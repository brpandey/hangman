defmodule Hangman.Server do
	use GenServer

	defmodule State do
		defstruct secret: "", pattern: "", max_wrong: 0, 
			correct_letters: HashSet.new, 
			incorrect_letters: HashSet.new, 
			incorrect_words: HashSet.new 
	end	

	@name __MODULE__

	@mystery_letter "-"

	@game_status_codes  %{
		game_won: {:game_won, 'GAME_WON', 0}, 
		game_lost: {:game_lost, 'GAME_LOST', 25}, 
		game_keep_guessing: {:game_keep_guessing, 'KEEP_GUESSING', -1}
	}

	@vsn "0"


	#####
	# External API
	def start_link(secret, max_wrong \\ 5) when is_binary(secret) do

		pattern = String.duplicate(@mystery_letter, String.length(secret))
		args = %State{secret: String.upcase(secret), max_wrong: max_wrong, pattern: pattern}
		options = [name: @name] #,  debug: [:trace]]

		GenServer.start_link(@name, args, options)

	end

	def mystery_letter, do: @mystery_letter

	def guess_letter(letter) when is_binary(letter) do
		GenServer.call @name, {:guess_letter, letter}
	end

	def guess_word(word) when is_binary(word) do
		GenServer.call @name, {:guess_word, word}
	end

	def game_status do
		GenServer.call @name, :game_status
	end

	def secret_length do
		GenServer.call @name, :secret_length
	end

	def another_game(secret, max_wrong \\ 5) when is_binary(secret) do
		GenServer.cast @name, {:another_game, secret, max_wrong}
	end

	def stop do
		GenServer.call @name, :stop
	end

	#####
	# GenServer implementation

	def init(secret, max_wrong) do

		pattern = String.duplicate(@mystery_letter, String.length(secret))

		state = %State{secret: String.upcase(secret), max_wrong: max_wrong, pattern: pattern}

		{ :ok, state }

	end

	@doc """
		Guess the specified letter and update the pattern state accordingly

		Returns:
			if correct, the :correct atom with the 
			string representation of the current game state
			(which will contain MYSTERY_LETTER in place of unknown
			letters)
			otherwise, the :incorrect atom and Nil
	"""

	def handle_call({:guess_letter, letter}, _from, state) do

		{:game_keep_guessing, _, _} = _game_status(state)

		letter = String.upcase(letter)

		case String.contains?(state.secret, letter) do 

			true -> 
				#Update pattern and game state
				pattern = Hangman.Pattern.update(state.pattern, state.secret, letter)

				state = %{ state | correct_letters: HashSet.put(state.correct_letters, letter),
					pattern: pattern }

				data = :correct_letter

			false ->
				#Update game state
				state = %{ state | incorrect_letters: HashSet.put(state.incorrect_letters, letter) }

				data = :incorrect_letter

		end

		#Update game status
		{ code, _, display } = _game_status(state)

		data = {data, code, state.pattern, display}

		{ :reply, data, state }

	end

	@doc """
		Guess the specified word and update the pattern state accordingly

		Returns:
			if correct, the :correct atom and the 
			game status tuple as the game has been won 
			(effectively saving another client call to get the game_status here)

			we also signal to shutdown the server at this point

			if incorrect, the :incorrect atom and nil
			
	"""
	def handle_call({:guess_word, word}, _from, state) do

		{:game_keep_guessing, _, _} = _game_status(state)

		word = String.upcase(word)

		case state.secret == word do 

			true -> 
				state = %{ state | pattern: word }

				data = :correct_word

			false ->
				state = %{ state | incorrect_words: HashSet.put(state.incorrect_words, word) }

				data = :incorrect_word
				
		end

		{ code, _, display } = _game_status(state)

		data = {data, code, state.pattern, display}

		{ :reply, data, state }

	end

	@doc """
		Returns the game status text
	"""

	def handle_call(:game_status, _from, state) do

		{ :reply, _game_status(state), state }

	end

	@doc """
		Returns the hangman secret length
	"""

	def handle_call(:secret_length, _from, state) do

		{ :reply, {:secret_length, String.length(state.secret)}, state }

	end


	def handle_call(:stop, _from, state) do

		{ :stop, :normal, :ok, state }

	end


	def handle_cast({:another_game, secret, max_wrong}, state) do

		# Reset the game state for use for another game by client
		pattern = String.duplicate(@mystery_letter, String.length(secret))

		state = %State{secret: String.upcase(secret), max_wrong: max_wrong, pattern: pattern}

		state = %State{ state | correct_letters: HashSet.new, 
			incorrect_letters: HashSet.new, 
			incorrect_words: HashSet.new}

		{ :noreply, state }

	end


	def format_status(_reason, [ _pdict, state ]) do
	
		[data: [{'State', "The current hangman server state is #{inspect state} and #{_game_status(state)}"}]]

	end


	@doc """
		Stops the hangman game server
	"""

	def terminate(_reason, _state) do

		#IO.puts "Terminating Hangman Server"
		:ok
	end


	#####
	# Helper functions

	defp _game_status(state) do

		status = 
			cond do
				state.secret == state.pattern -> 
					@game_status_codes[:game_won]

				Set.size(state.incorrect_letters) + 
				Set.size(state.incorrect_words) > state.max_wrong ->
					@game_status_codes[:game_lost]

				true -> @game_status_codes[:game_keep_guessing]

		end

		case status do

			{:game_lost, text, score} -> 
				{:game_lost, score, _display_status(state.pattern, score, text)}

			{status_code, text, _} -> 
				score =	Set.size(state.incorrect_letters) + 
					Set.size(state.incorrect_words) + 
					Set.size(state.correct_letters)
	
				{status_code, score, _display_status(state.pattern, score, text)}
		end

	end

	defp _display_status(pattern, score, text) do
		"#{pattern}; score=#{score}; status=#{text}"
	end

end