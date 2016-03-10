defmodule Game do
  @moduledoc """
  Module defines game abstraction which can handle
  a single hangman game or multiple hangman games.
  
  Runs each game or set of games sequentially.
  Therefore only one game is in play at any one time.
  
  Primary functions are `Game.load/3`, `Game.guess/2`, `Game.status/1`.
  """
  
  
	defstruct id: nil, 
  current: 0, #Current game index
	secret: "", pattern: "", score: 0,
	secrets: [],	patterns: [], scores: [],
	max_wrong: 0, correct_letters: MapSet.new, 
	incorrect_letters: MapSet.new, incorrect_words: MapSet.new
  
  @type t :: %__MODULE__{}
  
  @type id :: String.t
  
  @type result :: {t, tuple}
  
	@status_codes  %{
		game_won: {:game_won, 'GAME_WON', -2}, 
		game_lost: {:game_lost, 'GAME_LOST', 25}, 
		game_keep_guessing: {:game_keep_guessing, 'KEEP_GUESSING', -1},
		game_reset: {:game_reset, 'GAME_RESET', 0}
	}
  
	@mystery_letter "-"
  
  # Returns module attribute constant
  @spec mystery_letter :: String.t
	def mystery_letter, do: @mystery_letter
  
  
  @doc """
  Loads a new game state given new secret(s)
  """
  
  @spec load(id, String.t | [String.t], pos_integer) :: t
	def load(id_key, secret, max_wrong)
  when is_binary(id_key) and is_binary(secret) do
		pattern = String.duplicate(@mystery_letter, String.length(secret))
    
		%Game{id: id_key, secret: String.upcase(secret), 
			    pattern: pattern, max_wrong: max_wrong}
	end
  
  def load(id_key, secrets, max_wrong) when is_list(secrets) do
		#initialize the list of secrets to be uppercase 
		#initialize the list of patterns to fit the secrets length
		secrets = Enum.map(secrets, &String.upcase(&1))
    
		patterns = Enum.map(secrets, &String.duplicate(@mystery_letter, 
                                                   String.length(&1)))
    
		%Game{id: id_key, secret: List.first(secrets), 
          pattern: List.first(patterns), secrets: secrets, 
          patterns: patterns, max_wrong: max_wrong}
	end
  
  
  @doc """
  Runs guess data against game secret. Updates hangman pattern, status, and
  other game recordkeeping structures.

  Guesses follow two types

    * `{:guess_letter, letter}` - 	If correct, 
    returns the :correct_letter data tuple along with game
	  otherwise, returns the :incorrect_letter data tuple along with game

    * `{:guess_word, word}` - 	If correct, returns 
    the :correct_word data tuple along with game
	  If incorrect, returns the :incorrect_word data tuple with game
	  
	"""

  @spec guess(t, guess :: Guess.t) :: result
  def guess(%Game{} = game, {:guess_letter, letter}) do
    
    # assert we can guess :)
    { _, :game_keep_guessing, _} = status(game)
    
		letter = String.upcase(letter)
    
		result = cond do 
			String.contains?(game.secret, letter) -> 
        #letter found within secret
			  
				#Update pattern and game game
				pattern = Pattern.update(game.pattern, game.secret, letter)
        
				game = %{ game | 
					        correct_letters: 
                  MapSet.put(game.correct_letters, letter),					   
                  pattern: pattern }
        
				:correct_letter
      true -> #default: letter not found
        
				game = %{ game | 
					        incorrect_letters: 
                  MapSet.put(game.incorrect_letters, letter) }
        
				:incorrect_letter
		end
    
		#return updated game status
		{ _, code, display } = status(game)
    
    # return data tuple
		data = {game.id, result, code, game.pattern, display}
    
		#If the current game is finished check if there are remaining games
		case code do
			:game_keep_guessing -> data = {data, []} # mark the final results with []
			_ ->
				{game, data} = next(game.secrets, game, data)
		end
    
    {game, data}
  end
  
  
  def guess(%Game{} = game, {:guess_word, word}) do
		{ _, :game_keep_guessing, _ } = status(game) # Assert
    
		word = String.upcase(word)
    
		result = cond do
			game.secret == word -> 
				game = %{ game | pattern: word }
        
				:correct_word
      
				true ->
				game = %{ game | 
						      incorrect_words: 
                  MapSet.put(game.incorrect_words, word) }
        
				:incorrect_word
		end
    
		{ _, code, display } = status(game)
		data = { game.id, result, code, game.pattern, display }
    
		#If the current game is finished check if there are remaining games
		case code do
			:game_keep_guessing -> 
				data = {data, []}
			_ ->
				{game, data} = next(game.secrets, game, data)
		end
    
    {game, data}
  end
  
  
  # Helper function to check current game status code
  
  @spec status_code(t) :: tuple
	defp status_code(%Game{} = game) do
		cond do
			game.secret == "" ->
        @status_codes[:game_reset]
			game.secret == game.pattern -> 
				@status_codes[:game_won]
      incorrect_guesses(game) > game.max_wrong -> 
				@status_codes[:game_lost]
			true -> @status_codes[:game_keep_guessing]
		end
  end
  
  
  @doc """
  Returns current game status text
  """
  
  @spec status(t) :: tuple
  def status(%Game{} = game) do
    
    # small lambda to dry up functionality
    # and return status as text
    fn_textify = fn
      pattern, score, text ->
		    "#{pattern}; score=#{score}; status=#{text}"
	  end
    
		case status_code(game) do
			{:game_lost, text, score} -> 
				display_text = fn_textify.(game.pattern, score, text)
				{game.id, :game_lost, display_text}
			{:game_reset, text, _score} ->
				{game.id, :game_reset, text}
			{status_code, text, _} -> 
				score =	score(game)
				display_text = fn_textify.(game.pattern, score, text)
				{game.id, status_code, display_text}
		end
    
	end
  
  # Helper function to return current number of wrong guesses
  
  @spec incorrect_guesses(t) :: non_neg_integer
	defp incorrect_guesses(%Game{} = game) do
		Set.size(game.incorrect_letters) + 
		Set.size(game.incorrect_words)
	end
  
  # Helper function to return current game score
  
  @spec score(t) :: integer
	defp score(%Game{} = game) do
    
    case status_code(game) do
      # compute score if not lost and not reset
      {code, _, _} when code in [:game_keep_guessing, :game_won] ->
		    Set.size(game.incorrect_letters) + 
		    Set.size(game.incorrect_words) +
		    Set.size(game.correct_letters)
      {:game_lost, _, score} -> 
        # return default lost score if game lost
        score
    end
    
	end
  

  @docp """
  Returns next game, in the process of doing so checks
  if all games are over and if all secrets have been played against.
  If there are indeed games left to play, 
  updates state and transitions to next game 
  """
  @spec next(([] | [String.t]), t, term) :: {t, tuple}
  
	defp next([], _game, data), do: {%Game{}, data} 
  
	defp next(secrets, %Game{} = game, data)
  when is_list(secrets) do
		games_played = game.current + 1
    
		case Kernel.length(secrets) > games_played do
			true -> 	
        # Have games left to play
				# Updates game
				game = save_and_load(game)
				{game, {data, []}}
			false -> 	
        # Otherwise we have no more games left 
				# Store the current score in the game.scores list - insert
				# And update the game
				scores = List.insert_at(game.scores, game.current, score(game))
				game = %{ game | scores: scores }
				results = summary(game)
        
				# Clear and return game so server process can be reused, 
				# along with results data
				{%Game{}, {data, results}}
		end
	end

  
  # Saves result from current game, loads next game
  
  @spec save_and_load(t) :: t
	defp save_and_load(%Game{} = game) do
		'''
		First, do game archival steps
		'''
    
		#Store the game finishing pattern into the game.patterns list - replace
		patterns = List.replace_at(game.patterns, 
                               game.current, game.pattern)
    
		#Store the current score in the game.scores list - insert
		scores = List.insert_at(game.scores, game.current, score(game))
    
		#Increment the current game index
    
		#Update game
		game = %{ game | patterns: patterns, 
							scores: scores, current: game.current + 1 }
    
		'''
		Second, do refresh of current game
		'''
    
		#Replace the current pattern with new game's pattern
		#Replace the current secret with new game's secret
		#Reset the letter and word set counters
    
		#Update game
		%{ game | pattern: Enum.at(game.patterns, game.current),
			 secret: Enum.at(game.secrets, game.current),
			 correct_letters: MapSet.new, 
			 incorrect_letters: MapSet.new, 
			 incorrect_words: MapSet.new}
	end
  
  
  # Returns games summary status for when all games are over
  
  @spec summary(t) :: Keyword.t
	defp summary(%Game{} = game) do
		total_score = Enum.reduce(game.scores, 0, &(&1 + &2))
		games_played = game.current + 1
		average_score = total_score / games_played
    
		results = Enum.zip(game.secrets, game.scores)
    
		[status: :games_over, average_score: average_score, 
		 games: games_played, results: results]
	end
  


  @doc """
  Returns game information
  """

  @spec info(t) :: Keyword.t
  def info(%Game{} = g) do

    correct_letters = MapSet.to_list(g.correct_letters)
    incorrect_letters = MapSet.to_list(g.incorrect_letters)
    incorrect_words = MapSet.to_list(g.incorrect_words)
    
    letters = [correct: correct_letters, incorrect: incorrect_letters]
    words = [incorrect: incorrect_words]
    
    info = [
      id: g.id,
      current_game_index: g.current,
      secret: g.secret,
      pattern: g.pattern,
      score: g.score,
      secrets: g.secrets,
      patterns: g.patterns,
      scores: g.scores,
      max_wrong_guesses: g.max_wrong,
      guessed_letters: letters, 
      guessed_words: words
    ]

    info
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Game.info(t), opts)
      concat ["#Game<", info, ">"]
    end
  end

end
