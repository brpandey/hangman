defmodule Hangman.Player do


	defmodule State do
		defstruct name: "",  
			guessed_letters: [],
			game_server_pid: Nil,
			word_engine_pid: Nil
	end
	
	def start() do

		secrets = ["factual", "backpack"]
		player_name = "stanley"


		game_server_pid = Hangman.Cache.get_server(player_name, secrets)
		{^player_name, :secret_length, secret_length} =
			Hangman.Server.secret_length(player_game_server_pid)

		word_engine_pid = Hangman.Strategy.init(secret_length)

		%State{name: player_name, game_server_pid: server_pid, word_engine_pid}

		end

		loop(initial_state)


	end



	def loop(current_state) do
		receive do
			{_, :game_lost, _pattern, text} ->
				#Lost the game
				IO.puts text

			{_, :game_won, _pattern, text} ->
				#Won the game
				IO.puts text

			{:correct_letter, pattern, Nil} ->  
				Strategy.make_guess(:correct_letter, pattern)

			{:incorrect_letter, pattern, Nil} ->  
				Strategy.make_guess(:incorrect_letter, pattern)

			after 1000 ->
				IO.puts "message not received"

		end

	end


	defmodule Strategy do
		#Helper function

		defp _make_guess(guess_code, pattern) do

			case Hangman.Strategy.next_guess(guess_code, pattern) do
				{:word, word} ->
					Hangman.Server.guess_word word
					
				{:letter, letter} ->
					Hangman.Server.guess_letter letter
			end
		end


		defp _next_guess(guess_code, pattern) do
			

		end
	end
end