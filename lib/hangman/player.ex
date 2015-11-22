defmodule Hangman.Player do



	def start do

		Hangman.Server.secret_length

	end

	defp _make_guess(guess_code, pattern) do

		case Hangman.Strategy.next_guess(guess_code, pattern) do
			{:word, word} ->
				Hangman.Server.guess_word word
				
			{:letter, letter} ->
				Hangman.Server.guess_letter letter
		end
	end

	def run() do
		receive do
			{:secret_length, length} ->
				Hangman.Strategy.init(length)

			{_, _, {:game_lost, _}} ->

			{:correct_letter, pattern, Nil} ->  
				_make_guess(:correct_letter, pattern)

			{:correct_letter, pattern, {:game_won, text}} ->
				#Won the game

			{:incorrect_letter, pattern, Nil} ->  
				_make_guess(:correct_letter, pattern)

				


		end

	end


end