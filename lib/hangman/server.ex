defmodule Hangman.Server do
	use GenServer

	@moduledoc "Hangman.Server - hangman game server using GenServer.  
		Interacts with player client through public interface and
		maintains hangman game state"

	alias Hangman.Pattern, as: Pattern

	defmodule State do
		defstruct current: 0, #Current game index
			secret: "", pattern: "", score: 0,
			secrets: [],	patterns: [], scores: [],
			max_wrong: 0, correct_letters: HashSet.new, 
			incorrect_letters: HashSet.new, incorrect_words: HashSet.new
	end

	@name __MODULE__

	@mystery_letter "-"
	@max_wrong 5

	@game_status_codes  %{
		game_won: {:game_won, 'GAME_WON', 0}, 
		game_lost: {:game_lost, 'GAME_LOST', 25}, 
		game_keep_guessing: {:game_keep_guessing, 'KEEP_GUESSING', -1},
		game_reset: {:game_reset, 'GAME_RESET', 0}
	}

	@vsn "0"


	#####
	# External API


	@doc """
		Start public interface method with a single secret
	"""

	def start_link(secret, max_wrong \\ @max_wrong)

	def start_link(secret, max_wrong) when is_binary(secret) do

		pattern = String.duplicate(@mystery_letter, String.length(secret))

		args = %State{secret: String.upcase(secret), 
						pattern: pattern, max_wrong: max_wrong}
		
		options = [name: @name] #,  debug: [:trace]]

		GenServer.start_link(@name, args, options)

	end

	@doc """
		Start public interface method with a list of secrets
	"""
	def start_link(secrets, max_wrong) when is_list(secrets) do

		#initialize the list of secrets to be uppercase 
		#initialize the list of patterns to fit the secrets length
		secrets = Enum.map(secrets, &String.upcase(&1))

		patterns = Enum.map(secrets, &String.duplicate(mystery_letter, String.length(&1)))

		args = %State{secret: List.first(secrets), pattern: List.first(patterns),
							secrets: secrets, patterns: patterns, max_wrong: max_wrong}

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

'''
	def another_game(secret, max_wrong \\ 5) when is_binary(secret) do
		GenServer.cast @name, {:another_game, secret, max_wrong}
	end
'''

	def stop do
		GenServer.call @name, :stop
	end

	#####
	# GenServer implementation

	def init(state) do

		{ :ok, state }

	end

	@doc """
		{:guess_letter, letter}
		Guess the specified letter and update the pattern state accordingly

		If a correct guess, returns the :correct atom with the 
		string representation of the current game state 
		(which will contain MYSTERY_LETTER in place of unknown letters)
		otherwise, returns the :incorrect atom and Nil
	"""

	def handle_call({:guess_letter, letter}, _from, state) do

		{:game_keep_guessing, _} = check_game_status(state)

		letter = String.upcase(letter)

		result = cond do 
			String.contains?(state.secret, letter) -> #letter found within secret
			
				#Update pattern and game state
				pattern = Pattern.update(state.pattern, state.secret, letter)

				state = %{ state | 
					correct_letters: HashSet.put(state.correct_letters, letter),
					pattern: pattern }

				:correct_letter

			true -> #default: letter not found

				state = %{ state | 
					incorrect_letters: HashSet.put(state.incorrect_letters, letter) }

				:incorrect_letter
		end

		#return updated game status
		{ code, display } = check_game_status(state)

		data = {result, code, state.pattern, display}

		#If the current game is finished check if there are remaining games
		if code == :game_won or code == :game_lost do

			{state, data} = check_games_over(state.secrets, state, data)
		
		end

		{ :reply, {data, []}, state }

	end

	@doc """
		{:guess_word, word}
		Guess the specified word and update the pattern state accordingly

		If correct, returns the :correct atom and the game status tuple 
		as the game has been won (effectively saving another client call 
		to get the game_status here) we also signal to shutdown the 
		server at this point

		If incorrect, returns the :incorrect atom and nil	
	"""
	def handle_call({:guess_word, word}, _from, state) do

		{ :game_keep_guessing, _ } = check_game_status(state)

		word = String.upcase(word)

		result = cond do
				state.secret == word -> 
					state = %{ state | pattern: word }

					:correct_word

				true ->
					state = %{ state | 
						incorrect_words: HashSet.put(state.incorrect_words, word) }

					:incorrect_word
		end

		{ code, display } = check_game_status(state)

		data = {result, code, state.pattern, display}

		#If the current game is finished check if there are remaining games
		if code == :game_won or code == :game_lost do

			{state, data} = check_games_over(state.secrets, state, data)
		
		end

		{ :reply, {data, []}, state }

	end

	@doc """
		:game_status
		Returns the game status text
	"""
	def handle_call(:game_status, _from, state) do

		{ :reply, check_game_status(state), state }

	end

	@doc """
		:secret_length
		Returns the hangman secret length
	"""
	def handle_call(:secret_length, _from, state) do

		{ :reply, {:secret_length, String.length(state.secret)}, state }

	end

	@doc """
		:stop
		Stops the server is a normal graceful way
	"""
	def handle_call(:stop, _from, state) do

		{ :stop, :normal, :ok, state }

	end


'''
	def handle_cast({:another_game, secret, max_wrong}, state) do

		# Reset the game state for use for another game by client
		pattern = String.duplicate(@mystery_letter, String.length(secret))

		state = %State{secret: String.upcase(secret), max_wrong: max_wrong, pattern: pattern}

		state = %State{ state | correct_letters: HashSet.new, 
			incorrect_letters: HashSet.new, 
			incorrect_words: HashSet.new}

		{ :noreply, state }

	end
	'''


	def format_status(_reason, [ _pdict, state ]) do
	
		[data: [{'State', "The current hangman server state is #{inspect state} and #{check_game_status(state)}"}]]

	end


	@doc """
		Terminates the hangman game server
		No special cleanup other than refreshing the state
	"""
	def terminate(_reason, _state) do

		#IO.puts "Terminating Hangman Server"
		#state = %State{}
		:ok

	end


	#####
	# Helper functions

	defp check_game_status(state) do

		status = cond do

				state.secret == "" -> @game_status_codes[:game_reset]

				state.secret == state.pattern -> 
					@game_status_codes[:game_won]

				get_num_wrong_guesses(state) > state.max_wrong -> 
					@game_status_codes[:game_lost]

				true -> @game_status_codes[:game_keep_guessing]
		end

		case status do
			{:game_lost, text, score} -> 
				display_text = display_game_status(state.pattern, score, text)
				{:game_lost, display_text}

			{:game_reset, text, score} ->
				{:game_reset, text}

			{status_code, text, _} -> 
				score =	get_score(state)
				display_text = display_game_status(state.pattern, score, text)
				{status_code, display_text}
		end

	end

	defp get_num_wrong_guesses(state) do

		Set.size(state.incorrect_letters) + 
		Set.size(state.incorrect_words)

	end

	defp get_score(state) do
		
		Set.size(state.incorrect_letters) + 
		Set.size(state.incorrect_words) +
		Set.size(state.correct_letters)

	end

	defp display_game_status(pattern, score, text) do

		"#{pattern}; score=#{score}; status=#{text}"
	
	end

	defp check_games_over([], _state, data), do: {%State{}, data} 

	defp check_games_over(secrets, state, data) when is_list(secrets) do

		games_played = state.current + 1

		case Kernel.length(secrets) > games_played do

			true -> 	#Have games left to play

				#Updates state
				state = save_and_load_next_game(state)

				{state, {data, []}}

			false -> 	#Otherwise we have no more games left 

				#Store the current score in the state.scores list - insert
				#And update the state
				scores = List.insert_at(state.scores, state.current, get_score(state))

				state = %{ state | scores: scores }

				results = game_over_all_games_status(state)

				#Clear and return state so server process can be reused, 
				#along with results data
				{%State{}, {data, results}}

		end

	end

	defp game_over_all_games_status(state) do

		total_score = Enum.reduce(state.scores, 0, &(&1 + &2))
		
		games_played = state.current + 1

		average_score = total_score / games_played

		results = Enum.zip(state.secrets, state.scores)

		[status: :game_over, average_score: average_score, 
			games: games_played, results: results]

	end

	defp save_and_load_next_game(state) do

		'''
			First, do game archival steps
		'''

		#Store the game finishing pattern into the state.patterns list - replace
		patterns = List.replace_at(state.patterns, state.current, state.pattern)

		#Store the current score in the state.scores list - insert
		scores = List.insert_at(state.scores, state.current, get_score(state))

		#Increment the current game index

		#Update state
		state = %{ state | patterns: patterns, 
									scores: scores, current: state.current + 1 }

		'''
			Second, do refresh of current state steps
		'''

		#Replace the current pattern with new game's pattern
		#Replace the current secret with new game's secret
		#Reset the letter and word set counters

		#Update state
		%{ state | pattern: Enum.at(state.patterns, state.current),
					secret: Enum.at(state.secrets, state.current),
					correct_letters: HashSet.new, 
					incorrect_letters: HashSet.new, 
					incorrect_words: HashSet.new}
	end

end