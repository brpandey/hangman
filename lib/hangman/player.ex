defmodule Player do
  @moduledoc """
  Module handles player abstraction and defines player type

  Implements functionality to start a player, 
  choose letters, guess letters and words

  Heavily relies upon Round and Action functionality
  """

	defstruct name: "", 
  type: nil,
  round_no: 0,  
  round: %Round{},
  strategy: Strategy.new,
  game_no: 0, 
  games_summary: nil, 
  game_server_pid: nil, 
  event_server_pid: nil,    
  mystery_letter: Game.mystery_letter
  
  @type t :: %__MODULE__{}

  @type result :: {t, Round.result}

  @human :human
  @robot :robot
  

  @type kind :: :human | :robot

  def human, do: @human
  def robot, do: @robot
  
  
  # CREATE

  @doc """
  Returns new player, validates player type
  """

  @spec new(String.t, :atom, pid, pid) :: t
  def new(name, type, game_pid, event_pid)
  when is_binary(name) and is_atom(type)
  and is_pid(game_pid) and is_pid(event_pid) do
    
  	unless type in [@human, @robot] do 
      raise HangmanError, "invalid and unknown player type" 
    end
    
  	%Player{ name: name, type: type, 
  		       game_server_pid: game_pid, event_server_pid: event_pid }
  end

  # READ
  
  @doc """
  Returns true or false whether we've arrived at 
  the last word in possible words set
  """

  @spec last_word?(t) :: boolean
  def last_word?(%Player{} = p) do
    case Strategy.last_word(p.strategy) do 
      {:guess_word, ""} -> false
      {:guess_word, _} -> true 
    end
  end

  @doc """
  Returns true or false whether the game has been won
  """

  @spec game_won?(t) :: boolean
  def game_won?(%Player{} = p), do: p.round.status_code == :game_won


  @doc """
  Returns true or false whether the game has been lost
  """

  @spec game_lost?(t) :: boolean
  def game_lost?(%Player{} = p), do: p.round.status_code == :game_lost

  @doc """
  Returns true or false whether all games are over
  """

  @spec games_over?(t) :: boolean
  def games_over?(%Player{} = p), do: p.games_summary != nil

  @doc """
  Returns game summary as a string
  """

  @spec games_summary(Keyword.t) :: String.t
  def games_summary(args) when is_list(args) and is_tuple(Kernel.hd(args)) do
  	
		{:ok, avg} = Keyword.fetch(args, :average_score)
		{:ok, games} = Keyword.fetch(args, :games)
		{:ok, scores} = Keyword.fetch(args, :results)

		results = Enum.reduce(scores, "",  fn {k,v}, acc -> 
			acc <> " (#{k}: #{v})"  end)
			
		"Game Over! Average Score: #{avg}, " 
		<> "# Games: #{games}, Scores: #{results}"
	end

  @doc """
  Returns game round status
  """

  @spec status(t, :atom) :: Round.result
  def status(%Player{} = p, :game_round), do: Round.status(p)

  @doc """
  Returns games over status
  """

  @spec status(t, :atom) :: Round.result
  def status(%Player{} = p, :games_over) do
  	case games_over?(p) do
  		true -> {:games_over, p.games_summary}
  		false -> status(p, :game_round)
  	end
  end


	# UPDATE

  @doc """
  Routine starts a new player abstraction.

  Notifies player specific event server

  Setups game round.

  If player type is robot, makes first guess, and returns round status
  If player type is human retrieves letter choices to display
  """

  @spec start(t) :: result
	def start(%Player{} = p) do
    if p.game_no >= 1 do
      p = %Player{ name: p.name, type: p.type, 
                        game_server_pid: p.game_server_pid,
                        event_server_pid: p.event_server_pid,
                        game_no: p.game_no + 1 }
    else
      p = Kernel.put_in(p.game_no, p.game_no + 1)

      # Notify the event server that we've started playing hangman
      Player.Events.notify_start(p.event_server_pid, p.name)
    end

    result = 
      case p.type do
        @robot -> guess(p, :game_start)
        @human -> choices(p, :choose_letters, :game_start)
        _ -> raise HangmanError, "Invalid and unknown player type"
    end

    result
	end


  @doc """
  HUMAN Routine for human player type retrieves letter choices
  Setups new round, retrieves and returns letter choices
  """



  @spec choices(t, Guess.directive, :atom) :: {t, Guess.option}
	def choices(%Player{} = p, :choose_letters, options \\ nil) do
  	
    @human = p.type

    fn_run = fn ->
      p = 
        case options do
          :game_start -> 
            p |> Round.setup(:game_start) # Setup round
          nil ->
            p |> Round.setup # Setup round
        end
      
      # Retrieve top letter strategy options,
      # and then updating updating options with round specific information

      choices = Strategy.choose_letters(p.strategy)
      choices = Round.augment_choices(p, choices)

      {p, choices}
    end

    rescue_wrap(p, fn_run)
  end


  @doc """
  ROBOT Routine for robot player type guess
  Setups new round, performs guess, returns round status
  """

  @spec guess(t) :: result
  def guess(%Player{} = p) do
    @robot = p.type

    fn_run = fn ->
      p = p |> Round.setup # Setup round
      p = Action.perform(p, :robot_guess)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end

  @spec guess(t) :: result
  def guess(%Player{} = p, :game_start) do
    @robot = p.type

    fn_run = fn ->
      p = p |> Round.setup(:game_start) # Setup game start round
      p = Action.perform(p, :robot_guess)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end

  @doc """
  HUMAN Routine for human player type which perform guess of last remaining word

  Note: Somewhat of a hack for a human guess word, 
  we simplify the human guessing of words to just the last word
  """

  @spec guess(t, Guess.directive) :: result
	def guess(%Player{} = p, :guess_last_word) do
    @human = p.type

    fn_run = fn ->
      p = Action.perform(p, :guess_last_word)
      status = Round.status(p)

      # If we can supposedly keep guessing, flag as error since this should be end
      case status do
        {:game_keep_guessing, _} -> 
          raise HangmanError, 
          "Last word was not actual last word, secret not in hangman dictionary"
        _ -> {p, status} # Return normal return value
      end
    end

    rescue_wrap(p, fn_run)
	end

  @doc """
  HUMAN Routine for human player type which perform letter guesses

  Doesn't setup round since it was setup during choose letters stage.
  Issues action to guess letter and returns round status
  """


  @spec guess(t, Guess.t) :: result
  def guess(%Player{} = p, guess = {:guess_letter, l})
  when is_binary(l) do 

    @human = p.type

    fn_run = fn ->
      p = Action.perform(p, guess)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end

  # Delay the running of function object until this method
  # if error, return status code :game_reset along with error message
  # if not, return results of fn_run normally

  @spec rescue_wrap(t, (() -> result | no_return)) :: result
  defp rescue_wrap(%Player{} = p, fn_run) do
    value = 
      try do 
        fn_run.() 
      rescue
        e in HangmanError -> {p, {:game_reset, e.message}}
      end
    
    value
  end

  # DELETE

  @doc """
  Method returns empty player state
  """

  @spec delete(t) :: t
  def delete(%Player{} = _p), do:	%Player{}


  # EXTRA
  # Returns player information 
  @spec info(t) :: Keyword.t
  def info(%Player{} = p) do

    guess = 
      case p.round.guess do
        {} -> ""
        {_atom, token} -> token
      end
    
    round = [
        no: p.round.seq_no,
        guess: guess,
        guess_result: p.round.result_code,
        round_code: p.round.status_code,
        round_status: p.round.status_text,
        pattern: p.round.pattern
    ]
        
    _info = [
      name: p.name, 
      type: p.type,
      round_no: p.round_no,
      game_pid: p.game_server_pid,
      event_pid: p.event_server_pid,
      round_data: round
    ]
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Player.info(t), opts)
      concat ["#Player<", info, ">"]
    end
  end

end
