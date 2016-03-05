defmodule Hangman.Player do
  @moduledoc """
  Module handles player abstraction and defines player type

  Implements functionality to start a player, 
  choose letters, guess letters and words

  Heavily relies upon Player.Round and Round.Action functionality
  """

  alias Hangman.{Player, Player.Round, Player.Events, 
                 Round.Action, Strategy, Game}
  

	defstruct name: "", type: nil,
  round_no: 0,  round: %Hangman.Types.Game.Round{},
  strategy: Strategy.new,
  game_no: 0, games_summary: nil, game_server_pid: nil, 
  event_server_pid: nil,    
  mystery_letter: Game.Server.mystery_letter
  
  @type t :: %__MODULE__{}

  @type result :: {t, Round.result}

  @human :human
  @robot :robot
    
  # CREATE

  @doc """
  Returns new player, validates player type
  """

  @spec new(String.t, :atom, pid, pid) :: t
  def new(name, type, game_pid, event_pid)
  when is_binary(name) and is_atom(type)
  and is_pid(game_pid) and is_pid(event_pid) do
    
  	unless type in [@human, @robot] do 
      raise Hangman.Error, "invalid and unknown player type" 
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

  @spec status(t, :atom) :: tuple
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
      Events.Server.notify_start(p.event_server_pid, p.name)
    end

    case p.type do
      @robot ->
        fn_run = fn ->
          p = p |> Round.setup(:game_start) |> Action.perform(:guess)
          {p, Round.status(p)}
        end
        
        rescue_wrap(p, fn_run)

      @human -> 
        fn_run = fn ->
          p = p |> Round.setup(:game_start)
          choices = p |> Action.perform(:choose_letters)
          {p, choices}
        end

        rescue_wrap(p, fn_run)
      
      _ -> raise Hangman.Error, "Invalid and unknown player type"
    end
	end


  @doc """
  Routine for human player type retrieves letter choices
  Setups new round, retrieves and returns letter choices
  """

  @spec choose(t, :atom) :: result
  def choose(%Player{} = p, :letter), do: choose(p, p.type, :letter)

  @spec choose(t, :atom, :atom) :: result
	def choose(%Player{} = p, @human, :letter) do
  	
    fn_run = fn ->
      p = p |> Round.setup # Setup round
      choices = Action.perform(p, :choose_letters)
      {p, choices}
    end

    rescue_wrap(p, fn_run)
  end


  @doc """
  Routine for robot player type guess
  Setups new round, performs guess, returns round status
  """

  @spec guess(t) :: result
  def guess(%Player{} = p), do: guess(p, p.type)

  @spec guess(t, :atom) :: result
	def guess(%Player{} = p, @robot) do

    fn_run = fn ->
      p = p |> Round.setup # Setup round
      p = Action.perform(p, :guess)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end

  @doc """
  Routine for human player type which perform guess of last remaining word

  Note: Somewhat of a hack for a human guess word, 
  we simplify the human guessing of words to just the last word
  """

  @spec guess(t, :atom) :: result
  def guess(%Player{} = p, :last_word), do: guess(p, p.type, :last_word)

  @spec guess(t, :atom, :atom) :: result
	def guess(%Player{} = p, @human, :last_word) do

    fn_run = fn ->
      p = Action.perform(p, :guess_last_word)
      status = Round.status(p)

      # If we can supposedly keep guessing, flag as error since this should be end
      case status do
        {:game_keep_guessing, _} -> 
          raise Hangman.Error, 
          "Last word was not actual last word, secret not in hangman dictionary"
        _ -> {p, status} # Return normal return value
      end
    end

    rescue_wrap(p, fn_run)
	end

  @doc """
  Routine for human player type which perform letter guesses

  Doesn't setup round since it was setup during choose letters stage.
  Issues action to guess letter and returns round status
  """


  @spec guess(t, String.t, :atom) :: result
  def guess(%Player{} = p, l, :letter), do: guess(p, p.type, l, :letter)

  @spec guess(t, :atom, String.t, :atom) :: result
	def guess(%Player{} = p, @human, letter, :letter)
  when is_binary(letter) do

    fn_run = fn ->
      p = Action.perform(p, :guess_letter, letter)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end

  # Delay the running of function object until this method
  # if error, return status code :game_reset along with error message
  # if not, return results of fn_run normally

  @spec rescue_wrap(t, (() -> {t, tuple} | no_return)) :: result
  defp rescue_wrap(%Player{} = p, fn_run) do
    value = 
      try do 
        fn_run.() 
      rescue
        e in Hangman.Error -> {p, {:game_reset, e.message}}
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

  @spec info(t) :: Keyword.t
  def info(%Player{} = p) do

    round = [
        no: p.round.seq_no,
        guess: p.round.guess,
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
      info = Inspect.List.inspect(Hangman.Player.info(t), opts)
      concat ["#Hangman.Player<", info, ">"]
    end
  end

end
