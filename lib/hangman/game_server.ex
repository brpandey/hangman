defmodule Hangman.Game.Server do
	use GenServer
  
  require Logger
	
	@moduledoc """
  Module implements  hangman game server using GenServer.  
	Interacts with player client through public interface and
	maintains hangman game state
	"""
  
	alias Hangman.Pattern, as: Pattern
  
	defmodule State do
		defstruct current: 0, #Current game index
		secret: "", pattern: "", score: 0,
		secrets: [],	patterns: [], scores: [],
		max_wrong: 0, correct_letters: HashSet.new, 
		incorrect_letters: HashSet.new, incorrect_words: HashSet.new
	end
  
	@vsn "0"
	@name __MODULE__
	@mystery_letter "-"
	@max_wrong 5
  
	@game_status_codes  %{
		game_won: {:game_won, 'GAME_WON', -2}, 
		game_lost: {:game_lost, 'GAME_LOST', 25}, 
		game_keep_guessing: {:game_keep_guessing, 'KEEP_GUESSING', -1},
		game_reset: {:game_reset, 'GAME_RESET', 0}
	}
  
	#####
	# External API
  
  
	@doc """
	Start public interface method with a single secret
	"""
  
  @spec start_link(String.t, String.t, pos_integer) :: {:ok, pid}
	def start_link(player_name, secret, max_wrong \\ @max_wrong) do
		Logger.info "Starting Hangman Game Server"
		args = {player_name, do_load_game(secret, max_wrong)}
		options = [name: via_tuple(player_name)] #,  debug: [:trace]]
    
		GenServer.start_link(@name, args, options)
	end
  
  @doc """
  Routine returns game server pid from process registry using gproc
  If not found, returns :undefined
  """
  
  @spec whereis(String.t) :: pid | :atom
	def whereis(name) do
    :gproc.whereis_name({:n, :l, {:hangman_server, name}})
	end
  
  # Used to register / lookup process in process registry via gproc
  @spec via_tuple(String.t) :: {}
	defp via_tuple(name) do
		{:via, :gproc, {:n, :l, {:hangman_server, name}}}
	end
  
  # Returns module attribute constant
  @spec mystery_letter :: String.t
	def mystery_letter, do: @mystery_letter
  
  @doc """
  Loads new game state into server process. 
  Used primarily by game pid cache server
  """
  
  @spec load_game(pid, (String.t | [String.t]), pos_integer) :: no_return
	def load_game(hangman_pid, secret, max_wrong \\ @max_wrong)
  
	def load_game(hangman_pid, secret, max_wrong) when is_binary(secret) do
		GenServer.cast hangman_pid, {:load_game, secret, max_wrong}
	end
  
	def load_game(hangman_pid, secrets, max_wrong) when is_list(secrets) do
		GenServer.cast hangman_pid, {:load_games, secrets, max_wrong}
	end
  
  @doc """
  Issues guess letter call to GenServer, returns guess result
  """
  
  @spec guess_letter(pid, String.t) :: {}
	def guess_letter(hangman_server_pid, letter) when is_binary(letter) do
		GenServer.call hangman_server_pid, {:guess_letter, letter}
	end
  
  @doc """
  Issues guess word call to GenServer, returns guess result
  """
  
  @spec guess_word(pid, String.t) :: {}
	def guess_word(hangman_server_pid, word) when is_binary(word) do
		GenServer.call hangman_server_pid, {:guess_word, word}
	end
  
  @doc """
  Retrieves game server status data
  """
  
  @spec game_status(pid) :: {}
	def game_status(hangman_server_pid) do
		GenServer.call hangman_server_pid, :game_status
	end
  
  @doc """
  Retrieves game secret length number
  """
  
  @spec secret_length(pid) :: {}
	def secret_length(hangman_server_pid) do
		GenServer.call hangman_server_pid, :secret_length
	end
  
  '''
	def another_game(secret, max_wrong \\ 5) when is_binary(secret) do
	GenServer.cast @name, {:another_game, secret, max_wrong}
	end
  '''
  
  @doc """
  Issues request to stop GenServer
  """
  
  @spec stop(pid) :: {}
	def stop(hangman_server_pid) do
		GenServer.call hangman_server_pid, :stop
	end
  
	#####
	# GenServer implementation
  
  @doc """
  GenServer callback to initalize server process
  """
  
  @callback init({}) :: {}
	def init({ name, state }) do
		{ :ok, { name, state } }
	end
  
	@doc """
	Loads a new game
	"""
  
  @spec handle_cast({}, {}) :: {}
	def handle_cast({:load_game, secret, max_wrong}, {name, _state}) do
		state = do_load_game(secret, max_wrong)
    
		{ :noreply, {name, state} }
	end
  
	@doc """
	Loads a set of games
	"""
  
  @spec handle_cast({}, {}) :: {}  
	def handle_cast({:load_games, secret, max_wrong}, {name, _state}) do
		state = do_load_game(secret, max_wrong)
		
		{ :noreply, {name, state} }
	end
  
  
	@doc """
	{:guess_letter, letter}
	Guess the specified letter and update the pattern state accordingly
  
	If a correct guess, returns the :correct atom with the 
	string representation of the current game state 
	(which will contain MYSTERY_LETTER in place of unknown letters)
	otherwise, returns the :incorrect atom and nil
	"""
  
  @spec handle_call({}, {}, {}) :: {}
	def handle_call({:guess_letter, letter}, _from, {name, state}) do
		{ _, :game_keep_guessing, _} = check_game_status(name, state)
    
		letter = String.upcase(letter)
    
		result = cond do 
			String.contains?(state.secret, letter) -> #letter found within secret
			  
				#Update pattern and game state
				pattern = Pattern.update(state.pattern, state.secret, letter)
        
				state = %{ state | 
					         correct_letters: 
                   HashSet.put(state.correct_letters, letter),					   
                   pattern: pattern }
        
				:correct_letter
      
			  true -> #default: letter not found
          
				  state = %{ state | 
					           incorrect_letters: 
                     HashSet.put(state.incorrect_letters, letter) }
        
				:incorrect_letter
		end
    
		#return updated game status
		{ _, code, display } = check_game_status(name, state)
    
		data = {name, result, code, state.pattern, display}
    
		#If the current game is finished check if there are remaining games
		case code do
			:game_keep_guessing -> data = {data, []}
			_ ->
				{state, data} = check_all_games_over(state.secrets, state, data)
		end
    
		{ :reply, data, {name, state} }
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
  
  @spec handle_call({}, {}, {}) :: {}
	def handle_call({:guess_word, word}, _from, {name, state}) do
		{ _, :game_keep_guessing, _ } = check_game_status(name, state) # Assert
    
		word = String.upcase(word)
    
		result = cond do
			state.secret == word -> 
				state = %{ state | pattern: word }
        
				:correct_word
      
				true ->
				state = %{ state | 
						       incorrect_words: 
                   HashSet.put(state.incorrect_words, word) }
        
				:incorrect_word
		end
    
		{ _, code, display } = check_game_status(name, state)
		data = { name, result, code, state.pattern, display }
    
		#If the current game is finished check if there are remaining games
		case code do
			:game_keep_guessing -> 
				data = {data, []}
			_ ->
				{state, data} = check_all_games_over(state.secrets, state, data)
		end
    
		{ :reply, data, {name, state} }
	end
  
	@doc """
	Returns the game status text
	"""

  @spec handle_call(:atom, {}, {}) :: {}
	def handle_call(:game_status, _from, {name, state}) do
		{ :reply, check_game_status(name, state), {name, state} }
	end
  
	@doc """
	Returns the hangman secret length
	"""
  
  @spec handle_call(:atom, {}, {}) :: {}
	def handle_call(:secret_length, _from, {name, state}) do
		{_, _, status_text} = check_game_status(name, state)
		length = String.length(state.secret)
    
		# Let's piggyback the round status text with the secret length value
    
		{ :reply, {name, :secret_length, length, status_text}, {name, state} }
	end
  
	@doc """
	Stops the server is a normal graceful way
	"""
  
  @spec handle_call(:atom, {}, {}) :: {}
	def handle_call(:stop, _from, {name, state}) do
		{ :stop, :normal, {:ok, name}, state }
	end
  
  
  _ = """
  def handle_cast({:another_game, secret, max_wrong}, state) do
  
  # Reset the game state for use for another game by client
  pattern = String.duplicate(@mystery_letter, String.length(secret))
  
  state = %State{secret: String.upcase(secret), max_wrong: max_wrong, pattern: pattern}
  
  state = %State{ state | correct_letters: HashSet.new, 
  incorrect_letters: HashSet.new, 
  incorrect_words: HashSet.new}
  
  { :noreply, state }
  
  end
  """
  
  @doc """
  Used for debugging purposes, returns state data of server process
  """
  @spec format_status(term, [...]) :: [...]
	def format_status(_reason, [ _pdict, state ]) do
		[data: [{'State', "The current hangman server state is #{inspect state} and #{check_game_status("", state)}"}]]
	end
  
  
	@doc """
	Terminates the hangman game server
	No special cleanup other than refreshing the state
	"""
  
  @spec terminate(term, term) :: :ok
	def terminate(_reason, _state) do
		#Logger.info "Terminating Hangman Game Server"
		#state = %State{}
		:ok
	end
  
  
	#####
	# Helper functions
  
  # Loads a new game state given new secrets
  
  @spec do_load_game(String.t, pos_integer) :: struct()
	defp do_load_game(secret, max_wrong) when is_binary(secret) do
		pattern = String.duplicate(@mystery_letter, String.length(secret))
    
		%State{secret: String.upcase(secret), 
			     pattern: pattern, max_wrong: max_wrong}
	end
  
  @spec do_load_game([String.t], pos_integer) :: struct()
  defp do_load_game(secrets, max_wrong) when is_list(secrets) do
		#initialize the list of secrets to be uppercase 
		#initialize the list of patterns to fit the secrets length
		secrets = Enum.map(secrets, &String.upcase(&1))
    
		patterns = Enum.map(secrets, 
                        &String.duplicate(mystery_letter, String.length(&1)))
    
		%State{secret: List.first(secrets), pattern: List.first(patterns),
			     secrets: secrets, patterns: patterns, max_wrong: max_wrong}
	end
  
  
  # Helper function to check current game status code
  
  @spec check_game_status_code(struct) :: {}
	defp check_game_status_code(state) do
		cond do
			state.secret == "" -> @game_status_codes[:game_reset]
      
			state.secret == state.pattern -> 
				  @game_status_codes[:game_won]
      
          get_num_wrong_guesses(state) > state.max_wrong -> 
				  @game_status_codes[:game_lost]
      
			    true -> @game_status_codes[:game_keep_guessing]
		end
  end


  # Helper function to return game status text

  @spec check_game_status(String.t, struct) :: {}
  defp check_game_status(name, state) do

		case check_game_status_code(state) do
			{:game_lost, text, score} -> 
				display_text = display_game_status(state.pattern, score, text)
				{name, :game_lost, display_text}
			{:game_reset, text, _score} ->
				{name, :game_reset, text}
			{status_code, text, _} -> 
				score =	get_score(state)
				display_text = display_game_status(state.pattern, score, text)
				{name, status_code, display_text}
		end
    
	end
  
  # Helper function to return current number of wrong guesses

  @spec get_num_wrong_guesses(struct) :: non_neg_integer
	defp get_num_wrong_guesses(state) do
		Set.size(state.incorrect_letters) + 
		Set.size(state.incorrect_words)
	end

  # Helper function to return current game score
  
  @spec get_score(struct) :: integer
	defp get_score(state) do
    
    case check_game_status_code(state) do
      # compute score if not lost and not reset
      {code, _, _} when code in [:game_keep_guessing, :game_won] ->
		    Set.size(state.incorrect_letters) + 
		    Set.size(state.incorrect_words) +
		    Set.size(state.correct_letters)
      {:game_lost, _, score} -> 
        # return default lost score if game lost
        score
    end
        
	end
  
  # Helper routine to return score as text
  
  @spec display_game_status(String.t, integer, String.t) :: String.t
	defp display_game_status(pattern, score, text) do
		"#{pattern}; score=#{score}; status=#{text}"
	end


  # Checks if all games are over, if all secrets have been played against.
  # If there are games left to play, updates state and transitions
  # to next game 
  
  @spec check_all_games_over(([] | [String.t]), struct, term) :: {}
  
	defp check_all_games_over([], _state, data), do: {%State{}, data} 
  
	defp check_all_games_over(secrets, state, data) when is_list(secrets) do
		games_played = state.current + 1
    
		case Kernel.length(secrets) > games_played do
			true -> 	#Have games left to play
				#Updates state
				state = save_and_load_next_game(state)
				{state, {data, []}}
			false -> 	#Otherwise we have no more games left 
				#Store the current score in the state.scores list - insert
				#And update the state
				scores = List.insert_at(state.scores, state.current, 
                                get_score(state))
				state = %{ state | scores: scores }
				results = all_games_over_status(state)
        
				#Clear and return state so server process can be reused, 
				#along with results data
				{%State{}, {data, results}}
		end
	end

  # Returns games summary status for when all games are over
  
  @spec all_games_over_status(struct) :: Keyword.t
	defp all_games_over_status(state) do
		total_score = Enum.reduce(state.scores, 0, &(&1 + &2))
		games_played = state.current + 1
		average_score = total_score / games_played
    
		results = Enum.zip(state.secrets, state.scores)
    
		[status: :game_over, average_score: average_score, 
		 games: games_played, results: results]
	end
  
  # Saves result from current game, loads next game
  
  @spec save_and_load_next_game(struct) :: struct
	defp save_and_load_next_game(state) do
		'''
		First, do game archival steps
		'''
    
		#Store the game finishing pattern into the state.patterns list - replace
		patterns = List.replace_at(state.patterns, 
                               state.current, state.pattern)
    
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
