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
	def start_link(secret, max_wrong) do

		pattern = String.duplicate(@mystery_letter, String.length(secret))
		args = %State{secret: String.upcase(secret), max_wrong: max_wrong, pattern: pattern}
		options = [name: @name] #,  debug: [:trace]]

		GenServer.start_link(@name, args, options)

	end

	def mystery_letter, do: @mystery_letter

	def guess_letter(letter) do
		GenServer.call @name, {:guess_letter, letter}
	end

	def guess_word(word) do
		GenServer.call @name, {:guess_word, word}
	end

	def game_status do
		GenServer.call @name, :game_status
	end

	def secret_length do
		GenServer.call @name, :secret_length
	end

	def stop do
		GenServer.cast @name, :stop
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
				state = %{ state | correct_letters: HashSet.put(state.correct_letters, letter)}
				pattern = Hangman.Pattern.update(state.pattern, state.secret, letter)

				state = %{ state | pattern: pattern}
				data = {:correct_letter, pattern, Nil}

				#If no remaining mystery letters, we have our word
				if not String.contains?(state.pattern, @mystery_letter) 
					and state.pattern == state.secret do

						data = {:correct_letter, pattern, _game_status(state)}

					end

			false ->
				state = %{ state | incorrect_letters: HashSet.put(state.incorrect_letters, letter)}
				data = {:incorrect_letter, Nil, Nil}

		end

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

				data = {:correct_word, _game_status(state)}

				{ :reply, data, state }

			false ->
				state = %{ state | incorrect_words: HashSet.put(state.incorrect_words, word) }

				data = {:incorrect_word, Nil}

				{ :reply, data, state }
				
		end

	end

	@doc """
		Returns the game status text
	"""

	def handle_call(:game_status, _from, state) do

		{ code, text, score } = _game_status(state)
		display = "#{state.pattern}; score=#{score}; status=#{text}"

		data = { code, score, display }

		{ :reply, data, state }

	end

	@doc """
		Returns the hangman secret length
	"""

	def handle_call(:secret_length, _from, state) do

		{ :reply, String.length(state.secret), state }

	end


	def handle_cast(:stop, state) do

		{ :stop, state }

	end


	def format_status(_reason, [ _pdict, state ]) do
	
		[data: [{'State', "My current hangman server state is #{inspect state} and #{_game_status(state)}"}]]

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

			{:game_lost, _, _} -> 
				status
			{status_code, text, _} -> 
				score =	Set.size(state.incorrect_letters) + 
					Set.size(state.incorrect_words) + 
					Set.size(state.correct_letters)
	
				{status_code, text, score}
		end

	end

end