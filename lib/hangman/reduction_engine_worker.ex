defmodule Hangman.Reduction.Engine.Worker do
  use GenServer

  require Logger

  @name __MODULE__
  @possible_words_left 40

  alias Hangman.{Types.Reduction.Pass, Word.Chunks, Counter}
  alias Hangman.Pass.Server, as: PassServer
  alias Hangman.Pass.Writer, as: PassWriter

  def start_link(worker_id) do
    Logger.debug "Starting Engine Reduce Worker #{worker_id}"

    args = {}
    options = [name: via_tuple(worker_id)]

    GenServer.start_link(@name, args, options)
  end

  def reduce_and_store(worker_id, pass_key, regex_key, %MapSet{} = exc) do
    l = [worker_id, pass_key, regex_key, exc]

    Logger.debug "reduction engine worker #{worker_id}, " <> 
      "reduce and store arg list #{inspect l}"

    GenServer.call(via_tuple(worker_id), 
                   {:reduce_and_store, pass_key, regex_key, exc})
  end

  defp via_tuple(worker_id) do
    {:via, :gproc, {:n, :l, {:reduction_engine_worker, worker_id}}}
  end

  
  # instead of passing data, may want to call pass engine read data directly
  # leave it for now
  def handle_call({:reduce_and_store, pass_key, regex_key, exclusion}, 
                  _from, {}) do

    pass_info = do_reduce_and_store(pass_key, regex_key, exclusion)
    {:reply, pass_info, {}}
  end
  

  defp do_reduce_and_store(pass_key, regex_key, %MapSet{} = exclusion) do


    data = %Chunks{} = PassServer.read_chunks(pass_key)

    length_key = Chunks.get_key(data)

		# convert chunks into word stream, 
		# filter out words that don't regex match
		# do for all values in stream

    filtered_stream = data 
    |> Chunks.get_words_lazy |> Stream.filter(&regex_match?(&1, regex_key))
    
		# Populate counter object, now that we've created the new filtered chunks
    tally = Counter.new |> Counter.add_words(filtered_stream, exclusion)
    
		# Create new Chunks abstraction with filtered word stream
		new_data = Chunks.new(length_key, filtered_stream)

		pass_size = Chunks.get_count(new_data, :words)

    possible_txt = ""
    last_word = ""

		# if down to 1 word, return the last word
		cond do
      pass_size == 0 -> ""
#        raise "Word not in dictionary, pass size can't be zero"

			pass_size == 1 -> 
				last_word = Chunks.get_words_lazy(new_data)
        |> Enum.take(1) |> List.first

      pass_size > 1 and pass_size < @possible_words_left ->
        l = Chunks.get_words_lazy(new_data) |> Enum.take(pass_size)
        possible_txt = "Possible hangman words left, #{pass_size} words: #{inspect l}"
        last_word = ""

			pass_size > 1 -> last_word = ""

			true -> raise Hangman.Error, "Invalid pass_size value #{pass_size}"
		end

    # serialize writes through Hangman Pass Writer
    PassWriter.write(pass_key, new_data)

		%Pass{size: pass_size, tally: tally, 
           possible: possible_txt, last_word: last_word}    
  end
  
	defp regex_match?(word, compiled_regex)
  when is_binary(word) and is_nil(compiled_regex) == false do
    Regex.match?(compiled_regex, word)
	end

end
