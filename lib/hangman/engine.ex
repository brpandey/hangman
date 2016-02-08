defmodule Hangman.Pass.Engine do

  alias Hangman.{Dictionary, Types.Reduction.Pass, Word.Chunks, Counter}

	@moduledoc """
	Maintains the current hangman pass state for a given player, round number.

	Uses an ets table to track only the current pass state

	pass_key :: {id, game_no, round_no}
	ets_engine_key :: {:words, pass_key} | {:counter, pass_key}

	"""

	@ets_table_name :engine_pass_table

	def setup() do
		:ets.new(@ets_table_name, [:set, :named_table, :protected])
	end

	@doc "Initial engine reduce routine"
	def reduce(:game_start, {id, game_no, round_no} = pass_key, options)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# Asserts
		{:ok, true} =	Keyword.fetch(options, :game_start)
		{:ok, length_key}  = Keyword.fetch(options, :secret_length)
		
		# Since this is the first pass, grab the words and tally from
		# the Dictionary Cache

		# Subsequent lookups will be from the pass table

		chunks = %Chunks{} = Dictionary.Cache.lookup(:chunks, length_key)

		pass_size = Chunks.get_count(chunks, :words)

		tally = %Counter{} = Dictionary.Cache.lookup(:tally, length_key)

		pass_info = %Pass{ size: pass_size, tally: tally, only_word_left: ""}

		# Store pass info into ets table for round 2 (next pass)
		put_next_pass_chunks(chunks, pass_key)
	
		{pass_key, pass_info}
	end


	def reduce(:incorrect_letter, {id, game_no, round_no} = pass_key, options)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# leave this in until we are assured the regex is faster
		# {:ok, _incorrect_letter} = Keyword.fetch(options, :incorrect_letter)

		{:ok, exclusion_set} = Keyword.fetch(options, :guessed_letters)
		{:ok, regex_key} = Keyword.fetch(options, :regex_match_key)

		pass_info = do_reduce(pass_key, regex_key, exclusion_set)

		{pass_key, pass_info}
	end

	def reduce(:correct_letter, {id, game_no, round_no} = pass_key, options)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		{:ok, exclusion_set} = Keyword.fetch(options, :guessed_letters)
		{:ok, regex_key} = Keyword.fetch(options, :regex_match_key)

		pass_info = do_reduce(pass_key, regex_key, exclusion_set)

		{pass_key, pass_info}
	end

	defp do_reduce(pass_key, regex_key, %MapSet{} = exclusion_set) do

    IO.puts "In do reduce"

		# retrieve pass chunks from ets
		stored_chunks = %Chunks{} = get_pass_chunks(pass_key)
    length_key = Chunks.get_key(stored_chunks)

    IO.puts "In round pass, chunks is: #{inspect stored_chunks}"

		# convert chunks into word stream, 
		# filter out words that don't regex match
		# do for all values in stream

    filtered_stream = 
      stored_chunks |> Chunks.get_words_lazy
      |> Stream.filter(&regex_match?(&1, regex_key))

		# Populate counter object, now that we've created the new filtered stream
		tally = Enum.reduce(filtered_stream, Counter.new, fn head, acc ->
			Counter.add_unique_letters(acc, head, exclusion_set)
		end)

    IO.puts "In round pass, tally is: #{inspect tally}"

		# Create new Chunks abstraction with filtered word stream
		filtered_chunks = Chunks.new(length_key, filtered_stream)
		pass_size = Chunks.get_count(filtered_chunks, :words)

		# Store Chunks abstraction into ets for next pass
		put_next_pass_chunks(filtered_chunks, pass_key)

		# if down to 1 word, return the last word
		last_word = cond do
			pass_size == 1 -> 
				Chunks.get_words_lazy(filtered_chunks)
        |> Enum.take(1) |> List.first

			pass_size > 1 -> ""

			true -> raise "Invalid pass_size value"
		end

		pass = %Pass{ size: pass_size, tally: tally, only_word_left: last_word}

    IO.puts "In round pass #{inspect pass}"

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

    IO.puts("put_next_pass_chunks, ets #{inspect :ets.info(@ets_table_name)}")
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
    
        IO.puts("get_pass_chunks, ets #{inspect :ets.info(@ets_table_name)}")
				# return chunks :)
				chunks
		end

	end
end
