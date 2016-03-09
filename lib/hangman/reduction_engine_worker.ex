defmodule Reduction.Engine.Worker do
  use GenServer

  @moduledoc """
  Module is a GenServer that implements worker word reducer functionality.
  """

  require Logger

  @name __MODULE__
  @possible_words_left 40

  @doc """
  GenServer start_link wrapper function
  """
  
  @spec start_link(pos_integer) :: GenServer.on_start
  def start_link(worker_id) do
    Logger.debug "Starting Engine Reduce Worker #{worker_id}"

    args = {}
    options = [name: via_tuple(worker_id)]
    GenServer.start_link(@name, args, options)
  end
  
  @doc """
  Primary worker function, returns results of reduction pass
  """
  
  @spec reduce_and_store(pos_integer, Pass.key, Regex.t, map) :: Pass.t
  def reduce_and_store(worker_id, pass_key, regex_key, %MapSet{} = exc) do
    l = [worker_id, pass_key, regex_key, exc]

    Logger.debug "reduction engine worker #{worker_id}, " <> 
      "reduce and store arg list #{inspect l}"

    GenServer.call(via_tuple(worker_id), 
                   {:reduce_and_store, pass_key, regex_key, exc})
  end

  # Used to register / lookup process in process registry via gproc

  @spec via_tuple(String.t) :: tuple
  defp via_tuple(worker_id) do
    {:via, :gproc, {:n, :l, {:reduction_engine_worker, worker_id}}}
  end


	@doc """
	Terminate callback
	No special cleanup
	"""
  
  @callback terminate(term, term) :: :ok
	def terminate(_reason, _state) do
		Logger.info "Terminating Reduction Engine Worker Server"
		:ok
	end

  
  @doc """
  GenServer callback function to handle reduce and store request
  """

  @callback handle_call(:atom, Pass.key, Regex.t, map) :: tuple
  def handle_call({:reduce_and_store, pass_key, regex_key, exclusion}, 
                  _from, {}) do

    pass_info = do_reduce_and_store(pass_key, regex_key, exclusion)
    {:reply, pass_info, {}}
  end

  @docp """
  Primary worker function which retrieves current pass chunks data,
  filters words with regex, tallies reduced word stream, creates new
  Chunk abstraction and stores it back into words pass table

  If pass size happens to be small enough, will also return
  remaining hangman possible words left to aid in guess selection. 

  Returns pass data
  """

  @spec do_reduce_and_store(Pass.key, Regex.t, map) :: Pass.t
  defp do_reduce_and_store(pass_key, regex_key, %MapSet{} = exclusion) do

    # Request chunks data from Pass Cache
    data = %Chunks{} = Pass.Cache.get(:chunks, pass_key)

    length_key = Chunks.key(data)

		# convert chunks into word stream, 
		# filter out words that don't regex match
		# do for all values in stream

    filtered_stream = data 
    |> Chunks.get_words_lazy |> Stream.filter(&regex_match?(&1, regex_key))
    
		# Populate counter object, now that we've created new filtered chunks
    tally = Counter.new |> Counter.add_words(filtered_stream, exclusion)
    
		# Create new Chunks abstraction with filtered word stream
		new_data = Chunks.new(length_key, filtered_stream)

		pass_size = Chunks.count(new_data)

    possible_txt = ""
    last_word = ""
    
    # let's collect possible hangman words if pass size is small enough
    # and return them for guessing aid

		# if down to 1 word, return the last word
		cond do
      pass_size == 0 -> ""
      # Note: lets strategy handle error higher up, don't crash process
      # raise "Word not in dictionary, pass size can't be zero"

			pass_size == 1 -> 
				last_word = Chunks.get_words_lazy(new_data)
        |> Enum.take(1) |> List.first

      pass_size > 1 and pass_size < @possible_words_left ->
        l = Chunks.get_words_lazy(new_data) |> Enum.take(pass_size)

        possible_txt = 
            "Possible hangman words left, #{pass_size} words: #{inspect l}"

        last_word = ""

			pass_size > 1 -> last_word = ""

			true -> raise HangmanError, "Invalid pass_size value #{pass_size}"
		end

    # serialize writes through Hangman Pass Writer
    Pass.Writer.write(pass_key, new_data)

		%Pass{size: pass_size, tally: tally, 
           possible: possible_txt, last_word: last_word}    
  end
  

  # Helper function to perform actual regex match
  @spec regex_match?(String.t, Regex.t) :: boolean
	defp regex_match?(word, compiled_regex)
  when is_binary(word) and is_nil(compiled_regex) == false do
    Regex.match?(compiled_regex, word)
	end

end
