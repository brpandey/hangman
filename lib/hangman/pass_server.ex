defmodule Hangman.Pass.Server do
  use GenServer

  require Logger

  alias Hangman.{Types.Reduction.Pass, Word.Chunks, Counter, Reduction.Engine}
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


  # External API

  def start_link() do
    Logger.info "Starting Hangman Pass Server"
    args = {}
    options = []
    GenServer.start_link(@name, args, options)
  end

	def stop(pid) do
		GenServer.call pid, :stop
	end

  def init(_) do
    setup()
    {:ok, {}}
  end

	def handle_call(:stop, _from, {}) do
		{ :stop, :normal, :ok, {}}
	end 

	def terminate(_reason, _state) do
		:ok
	end

  # Reduction Engine Abstraction Methods

	defp setup() do
		:ets.new(@ets_table_name, [:set, :named_table, :public])
	end



  # request not serialized through server process, since we are doing reads
	# game start initial pass routine
	def get_pass(:game_start, {id, game_no, round_no} = pass_key, reduce_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# Asserts
		{:ok, true} =	Keyword.fetch(reduce_key, :game_start)
		{:ok, length_key}  = Keyword.fetch(reduce_key, :secret_length)
		
		# Since this is the first pass, grab the words and tally from
		# the Dictionary Cache

		# Subsequent lookups will be from the pass table


		chunks = %Chunks{} = DictCache.Server.lookup(:chunks, length_key)
		tally = %Counter{} = DictCache.Server.lookup(:tally, length_key)

		pass_size = Chunks.get_count(chunks, :words)
		pass_info = %Pass{ size: pass_size, tally: tally, last_word: ""}

		# Store pass info into ets table for round 2 (next pass)
    Hangman.Pass.Writer.write(pass_key, chunks)
	
		{pass_key, pass_info}
	end

  # game keep guessing engine pass routine
	def get_pass(:game_keep_guessing, {id, game_no, round_no} = pass_key, 
               reduce_key)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do
    
		{:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
		{:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)
    
    pass_info = Engine.reduce(pass_key, regex_key, exclusion_set)

		{pass_key, pass_info}
	end

_ = """
Moved to engine reduce worker and pass writer


  # Private reduce method that actually does the reduce
  # Loads Chunks for the current pass, and reduces word
  # stream given regex filter
	defp do_reduce(:regex, pass_key, regex_key, %MapSet{} = exclusion_set) do

		# retrieve pass chunks from ets
		stored_chunks = %Chunks{} = read_pass_chunks(pass_key)
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
		write_next_pass_chunks(filtered_chunks, pass_key)

    possible_txt = ""

		# if down to 1 word, return the last word
		last_word = cond do
      pass_size == 0 -> raise "Pass size can't be zero"
			pass_size == 1 -> 
				Chunks.get_words_lazy(filtered_chunks)
        |> Enum.take(1) |> List.first

      pass_size > 1 and pass_size < @possible_words_left ->
        l = Chunks.get_words_lazy(filtered_chunks) |> Enum.take(pass_size)
        possible_txt = "Possible hangman words left, {pass_size} words: {inspect l}"
        ""

			pass_size > 1 -> ""

			true -> raise "Invalid pass_size value {pass_size}"
		end

		pass = %Pass{ size: pass_size, tally: tally, 
                  possible: possible_txt, last_word: last_word}

    #IO.puts "In round pass {inspect pass}"

    pass
	end

	defp regex_match?(word, compiled_regex) 
  when is_binary(word) and is_nil(compiled_regex) == false do
		# {:ok, compiled_regex} = Regex.compile(regex)
		Regex.match?(compiled_regex, word)
	end

	# "store next pass chunks into ets table with pass key"
	defp write_next_pass_chunks(%Chunks{} = chunks, {id, game_no, round_no})
	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		next_pass_key = {id, game_no, round_no + 1}

		:ets.insert(@ets_table_name, {next_pass_key, chunks})

	end

"""

	# "get pass chunks from ets table with pass key"
	def read_chunks({id, game_no, round_no} = pass_key)
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
