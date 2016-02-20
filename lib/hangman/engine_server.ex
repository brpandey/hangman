defmodule Hangman.Reduction.Engine.Server do
  use GenServer

  require Logger

  alias Hangman.{Types.Reduction.Pass, Word.Chunks, Counter}
  alias Hangman.Dictionary.Cache, as: DictCache

	@moduledoc """
	Maintains the current hangman words reduction state 
  for a given player, round number.

	Uses an ets table to track only the current pass state

	pass_key :: {id, game_no, round_no}
	ets_engine_key :: {:words, pass_key} | {:counter, pass_key}

	"""
  @name __MODULE__
	@ets_table_name :engine_pass_table

  @possible_words_left 40

  # External API

  def start_link(dict_cache_pid) when is_pid(dict_cache_pid) do
    Logger.info "Starting Hangman Engine Server"
    args = {dict_cache_pid}
    options = []
    GenServer.start_link(@name, args, options)
  end

  def reduce(pid, :game_start,  {id, game_no, round_no} = pass_key, reduce_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
    GenServer.call pid, {:reduce, :game_start, pass_key, reduce_key}
  end

  def reduce(pid, :game_keep_guessing,  
             {id, game_no, round_no} = pass_key, reduce_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
    GenServer.call pid, {:reduce, :game_keep_guessing, pass_key, reduce_key}
  end

	def stop(pid) do
		GenServer.call pid, :stop
	end

  def init({dict_cache_pid}) do
    setup()
    {:ok, {dict_cache_pid}}
  end

  def handle_call({:reduce, :game_start, pass_key, reduce_key}, _from, {dpid}) do
    data = do_reduce(:game_start, pass_key, reduce_key, dpid)
    {:reply, data, {dpid}}
  end

  def handle_call({:reduce, :game_keep_guessing, pass_key, reduce_key}, 
                  _from, {dpid}) do
    data = do_reduce(:game_keep_guessing, pass_key, reduce_key)
    {:reply, data, {dpid}}
  end

	def handle_call(:stop, _from, {dpid}) do
		{ :stop, :normal, :ok, {dpid}}
	end 

	def terminate(_reason, _state) do
		:ok
	end

  # Reduction Engine Abstraction Methods


	defp setup() do
		:ets.new(@ets_table_name, [:set, :named_table, :protected])
	end

  # game keep guessing engine reduce routine
	defp do_reduce(:game_keep_guessing, 
                 {id, game_no, round_no} = pass_key, reduce_key)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		{:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
		{:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)

		pass_info = do_reduce(:regex, pass_key, regex_key, exclusion_set)

		{pass_key, pass_info}
	end

	# game start engine reduce routine
	defp do_reduce(:game_start, {id, game_no, round_no} = pass_key, 
                 reduce_key, pid)
	when is_binary(id) and is_number(game_no) and is_number(round_no) 
    and is_pid(pid) do

		# Asserts
		{:ok, true} =	Keyword.fetch(reduce_key, :game_start)
		{:ok, length_key}  = Keyword.fetch(reduce_key, :secret_length)
		
		# Since this is the first pass, grab the words and tally from
		# the Dictionary Cache

		# Subsequent lookups will be from the pass table

		chunks = %Chunks{} = DictCache.Server.lookup(pid, :chunks, length_key)

		pass_size = Chunks.get_count(chunks, :words)

		tally = %Counter{} = DictCache.Server.lookup(pid, :tally, length_key)

		pass_info = %Pass{ size: pass_size, tally: tally, last_word: ""}

		# Store pass info into ets table for round 2 (next pass)
		put_next_pass_chunks(chunks, pass_key)
	
		{pass_key, pass_info}
	end




  # Private reduce method that actually does the reduce
  # Loads Chunks for the current pass, and reduces word
  # stream given regex filter
	defp do_reduce(:regex, pass_key, regex_key, %MapSet{} = exclusion_set) do

		# retrieve pass chunks from ets
		stored_chunks = %Chunks{} = get_pass_chunks(pass_key)
    length_key = Chunks.get_key(stored_chunks)

		# convert chunks into word stream, 
		# filter out words that don't regex match
		# do for all values in stream

    filtered_stream = stored_chunks 
    |> Chunks.get_words_lazy |> Stream.filter(&regex_match?(&1, regex_key))
    
		# Populate counter object, now that we've created the new filtered chunks
    tally = Counter.new |> Counter.add_words(filtered_stream, exclusion_set)

		# Create new Chunks abstraction with filtered word stream
		filtered_chunks = Chunks.new(length_key, filtered_stream)
		pass_size = Chunks.get_count(filtered_chunks, :words)

		# Store Chunks abstraction into ets for next pass
		put_next_pass_chunks(filtered_chunks, pass_key)

    possible_txt = ""

		# if down to 1 word, return the last word
		last_word = cond do
      pass_size == 0 -> raise "Pass size can't be zero"
			pass_size == 1 -> 
				Chunks.get_words_lazy(filtered_chunks)
        |> Enum.take(1) |> List.first

      pass_size > 1 and pass_size < @possible_words_left ->
        l = Chunks.get_words_lazy(filtered_chunks) |> Enum.take(pass_size)
        possible_txt = "Possible hangman words left, #{pass_size} words: #{inspect l}"
        ""

			pass_size > 1 -> ""

			true -> raise "Invalid pass_size value #{pass_size}"
		end

		pass = %Pass{ size: pass_size, tally: tally, 
                  possible: possible_txt, last_word: last_word}

    #IO.puts "In round pass #{inspect pass}"

    pass
	end

	defp regex_match?(word, compiled_regex) 
  when is_binary(word) and is_nil(compiled_regex) == false do
		#{:ok, compiled_regex} = Regex.compile(regex)
		Regex.match?(compiled_regex, word)
	end

	# "store next pass chunks into ets table with pass key"
	defp put_next_pass_chunks(%Chunks{} = chunks, {id, game_no, round_no})
	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		next_pass_key = {id, game_no, round_no + 1}

		:ets.insert(@ets_table_name, {next_pass_key, chunks})

	end

	# "get pass chunks from ets table with pass key"
	defp get_pass_chunks({id, game_no, round_no} = pass_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
		
		# Using match instead of lookup, to keep processing on the ets side
		case :ets.match_object(@ets_table_name, {pass_key, :_}) do
			[] -> raise "counter not found for key: #{inspect pass_key}"

			[{_key, chunks}] ->
				%Chunks{} = chunks # quick assert

				# delete this current pass in the table, since we only keep 1 pass for each user
				:ets.match_delete(@ets_table_name, {pass_key, :_})
    
				# return chunks :)
				chunks
		end

	end
end
