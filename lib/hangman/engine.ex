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
		load(@ets_table_name)
	end

	def load(table_name) do		
		:ets.new(table_name, [:set, :named_table, :protected])
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
		{:ok, regex} = Keyword.fetch(options, :regex)

		pass_info = do_round_pass(pass_key, regex, exclusion_set)

		{pass_key, pass_info}
	end

	def reduce(:correct_letter, {id, game_no, round_no} = pass_key, options)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		{:ok, exclusion_set} = Keyword.fetch(options, :guessed_letters)
		{:ok, regex} = Keyword.fetch(options, :regex)

		pass_info = do_round_pass(pass_key, regex, exclusion_set)

		{pass_key, pass_info}
	end

	defp do_round_pass(pass_key, regex, %MapSet{} = exclusion_set)
	when is_binary(regex) do

		# retrieve pass chunks from ets
		chunks = %Chunks{} = get_pass_chunks(pass_key)

		# convert chunks into word stream, 
		# filter out words that don't regex match
		# do for all values in stream => Stream.run
		filtered_word_stream = Chunks.get_words_lazy(chunks)
		|> Stream.filter(&Engine.regex_match?(&1, regex))
		|> Stream.each(&IO.puts/1)
		|> Stream.run

		# Populate counter object, now that we've created the new filtered stream
		tally = Enum.reduce(filtered_word_stream, Counter.new, fn head, acc ->
			Counter.add_unique_letters(acc, head, exclusion_set)
		end)

		# Create new Chunks abstraction with filtered word stream
		chunks = Chunks.new(filtered_word_stream)

		pass_size = Chunks.get_count(chunks, :words)

		# Store Chunks abstraction into ets for next pass
		put_next_pass_chunks(chunks, pass_key)

		# if down to 1 word, return the last word
		only_word_left = cond do
			pass_size == 1 -> 
				Chunks.get_words_lazy |> Enum.take(1)
			pass_size > 1 -> ""
			true -> raise "Invalid pass_size value"
		end

		%Pass{ size: pass_size, tally: tally, only_word_left: only_word_left}

	end

	def regex_match?(word, regex) when is_binary(word) and is_binary(regex) do
		{:ok, compiled_regex} = Regex.compile(regex)
		Regex.match?(compiled_regex, word)
	end

	@doc "store next pass chunks into ets table with pass key"
	def put_next_pass_chunks(%Chunks{} = chunks, {id, game_no, round_no})
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
		next_pass_key = {id, game_no, round_no + 1}
		:ets.insert(@ets_table_name, {next_pass_key, chunks})
	end

	@doc "get pass chunks from ets table with pass key"
	def get_pass_chunks({id, game_no, round_no} = pass_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
		
		# Using match instead of lookup, to keep processing on the ets side
		case :ets.match_object(@ets_table_name, {pass_key, :_}) do
			[] -> raise "counter not found for key: #{inspect pass_key}"

			chunks ->
				%Chunks{} = chunks # quick assert

				# delete this current pass in the table, since we only keep 1 pass for each user
				:ets.match_delete(@ets_table_name, {pass_key, :_})

				# return chunks :)
				chunks
		end
	end
end
