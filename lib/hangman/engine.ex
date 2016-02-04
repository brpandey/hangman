defmodule Hangman.Pass.Engine do

  alias Hangman.{Types.Reduction.Pass}

	@moduledoc """
	Maintains the current hangman pass state for a given player, round number.

	Uses an ets table to track only the current pass state

	pass_key :: {id, game_no, round_no}
	ets_engine_key :: {:words, pass_key} | {:counter, pass_key}

	"""

	@ets_table_name :hangman_pass_engine

	def setup() do
		load(@ets_table_name)
	end

	def load(table_name) do
		
		:ets.new(table_name, [:set, :named_table, :protected])
		
	end

	@doc "Initial engine reduce routine"

	def reduce(:game_start, 
		{id, game_no, round_no} = _pass_key, filter_options) 
		when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# Asserts
		{:ok, true} =	Keyword.fetch(filter_options, :game_start)
		{:ok, length_key}  = Keyword.fetch(filter_options, :secret_length)
		
		# simulate_reduce_sequence(game_no, 1)

		# Retrieve initial tally from Cache

		tally = Hangman.Dictionary.Cache.lookup_tally(length_key)

		# Retrieve words list from Cache as well

		pass_info = %Pass{tally: tally}
		#pass_info = %Pass{ size: size, tally: tally, only_word_left: ""}

		{game_no, round_no, pass_info}
	end


	def reduce(:incorrect_letter, 
 		{id, game_no, round_no} = _pass_key, filter_options) 
 		when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# leave this in until we are assured the regex is faster
		{:ok, _incorrect_letter} = Keyword.fetch(filter_options, :incorrect_letter)

		{:ok, _exclusion_filter_set} = Keyword.fetch(filter_options, :guessed_letters)
		{:ok, _regex} = Keyword.fetch(filter_options, :regex)
		
	end

end