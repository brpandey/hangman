defmodule Hangman.Player do

	'''
	def init(player_name) do

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

			{_, :game_lost, _pattern, text} ->
				#Lost the game
				IO.puts text

			{_, :game_won, _pattern, text} ->
				#Won the game
				IO.puts text

			{:correct_letter, pattern, Nil} ->  
				_make_guess(:correct_letter, pattern)


			{:incorrect_letter, pattern, Nil} ->  
				_make_guess(:incorrect_letter, pattern)

		end

	end
	'''

end