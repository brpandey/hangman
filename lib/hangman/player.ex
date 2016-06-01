defmodule Hangman.Player do

  @moduledoc """
  Module for creating players and maximizing our winning chances in conjunction
  with the player strategy against the 'implicit' other player, the `game server`.
  Handles choosing letters, guessing letters and words.

  In `Hangman` we have two players.  One explict - the one guessing, the other
  implicit, 'the game', 'the user tracking the penalties', or 'the stumper
  stumping the guesser with hard words'.  In this instance, the `Player` is
  merely the user making and choosing the guess selections.  

  The `human` player is given the choice of the top letter choices to choose
  from and is able to make an interactive guess.  The `robot` player is reliant
  on the game strategy to automatically self select the best guess.

  Player is one of four modules that drive the game play mechanics, the others 
  being `Round`, `Strategy`.

  Player encapsulates the data used along with Strategy data. `Round` functionality
  extends the scope of the player to handle the actual game round details.

  NOTE: Should a player submit a secret hangman word that does not actually
  reside in the `Dictionary.Cache`, the game will currently be prematurely 
  aborted.
  """

  alias Hangman.{Player, Round, Strategy, Game}

  defstruct name: "", pid: nil,
  type: nil,
  round_no: 0,  
  round: %Round{},
  strategy: Strategy.new,
  game_no: 0, 
  games_summary: nil, 
  game_server_pid: nil, 
  event_server_pid: nil,    
  mystery_letter: Game.mystery_letter


  @opaque t :: %__MODULE__{}

  @typedoc "Standardizes format around player result"
  @type result :: {t, Round.result}

  @typedoc "Defines player kind"
  @type kind :: :human | :robot

  @typedoc "Defines player key used with `Game.Server`"
  @type key :: {id :: String.t, client_pid :: pid}

  @human :human
  @robot :robot

  def human, do: @human
  def robot, do: @robot
  
  
  # CREATE

  @doc """
  Returns new `Player`, validates `player` type
  """

  @spec new(String.t, :atom, pid, pid) :: t
  def new(name, type, game_pid, event_pid)
  when is_binary(name) and is_atom(type)
  and is_pid(game_pid) and is_pid(event_pid) do
    
    unless type in [@human, @robot] do 
      raise HangmanError, "invalid and unknown player type" 
    end
    
    %Player{ name: name, type: type, pid: self(),
             game_server_pid: game_pid, event_server_pid: event_pid }
  end

  # READ
  
  @doc """
  Returns `true` or `false` whether we've arrived at 
  the last word in possible words set
  """

  @spec last_word?(t) :: boolean
  def last_word?(%Player{} = p) do
    case Strategy.last_word(p.strategy) do 
      {:guess_word, ""} -> false
      {:guess_word, _} -> true 
    end
  end


  # REFACTOR

  # We are having to do all this extra inference to figure out what state we are
  # Would be simpler just to have the correct state in round.status_code
  # and p.games_summary merged into one

  # Simple helper routine to detect if player is at game over and game start

  @spec game_start_or_over_check(Player.t) :: tuple
  def game_start_or_over_check(%Player{} = player) do

    # If a single game is finished, check if all the games are over, 
    # otherwise proceed to next game.  Else game over

    case p.round.status_code == :game_won or 
    p.round.status_code == :game_lost do
      
      true -> # Single game finished

        case p.games_summary != nil do # All games over?
          # All games finished
          true -> {:games_over}

          # Still more games left
          false -> {:game_start}
        end

      false -> # Start guessing
        {:game_keep_guessing}
    end
  end

  @doc """
  Returns `game` status
  """

  @spec status(t) :: Round.result
  def status(%Player{} = p) do

    case p.games_summary != nil do
      # if games are over
      true -> {:games_over, p.games_summary}

      # if games still left
      false ->
          # check if the single game is over
          case p.round.status_code == :game_won or 
          p.round.status_code == :game_lost do

            true -> {:game_keep_guessing}
            false -> Round.status(p)
          end
    end
  end


  @doc """
  Returns `game` summary as a string.  Includes `number` of games played, `average` 
  score per game, per game `score`.
  """

  @spec games_summary(Game.summary) :: String.t
  def games_summary(args) when is_list(args) and is_tuple(Kernel.hd(args)) do
    
    {:ok, avg} = Keyword.fetch(args, :average_score)
    {:ok, games} = Keyword.fetch(args, :games)
    {:ok, scores} = Keyword.fetch(args, :results)

    results = Enum.reduce(scores, "",  fn {k,v}, acc -> 
      acc <> " (#{k}: #{v})"  end)
      
    "Game Over! Average Score: #{avg}, " 
    <> "# Games: #{games}, Scores: #{results}"
  end


  # UPDATE

  @doc """
  Routine starts a new `Player`. Notifies player specific event server.
  Setups game round.

  If type is `robot`, makes initial guess, then returns round status.
  If type is `human`, retrieves top letter choices to display
  """

  @spec start(t) :: result
  def start(%Player{} = p) do

    # If we are on more than 1 game get 
    # e.g. if we've already played our first game
    if p.game_no >= 1 do
      # Copy over the state from the prior player game
      p = %Player{ name: p.name, type: p.type, pid: p.pid, 
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
        @robot -> guess(p, :robot, :game_start)
        @human -> guess(p, :human, :choose_letters, :game_start)
        _ -> raise HangmanError, "Invalid and unknown player type"
    end

    result
  end


  @doc """
  Routine for `:human` player type.
  Setups new `round`, retrieves and returns top letter choices.
  """

  @spec guess(t, kind, Guess.directive, :atom) :: {t, Guess.option}
  def guess(%Player{} = p, :human, :choose_letters, options \\ nil) do
    
    @human = p.type

    fn_run = fn ->
      p = 
        case options do
          :game_start -> p |> Round.setup(:game_start) # Setup round
          nil -> p |> Round.setup # Setup round
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
  Routine for `:robot` player type. Sets up new `round`, 
  performs `auto-generated` guess, returns round `status`
  """

  #@spec guess(p :: t, mode :: none | :atom) :: result

  def guess(%Player{} = p, :robot, mode \\ nil) when is_atom(mode) do
    @robot = p.type

    fn_run = fn ->

      p = 
        case mode do
          :game_start -> Round.setup(p, :game_start) # Setup game start round
          nil -> Round.setup(p) # Setup round
        end
      
      guess = Strategy.make_guess(p.strategy)
      round_info = Round.guess(p, guess)
      p = Round.update(p, round_info)
      {p, Round.status(p)}

    end

    rescue_wrap(p, fn_run)
  end

  @doc """
  Routine for `:human` player type.

  Comes in two modes
    * `:guess_last_word` - performs guess of last remaining word
    Note: Somewhat of an oversimplification for a `human` guess word, 
    we simplify the `human` guessing of words to just the `last` word

    * `{:guess_letter, letter}` - doesn't setup round since it 
    was already setup during the `choose letters` stage. Issues action 
    to `guess` and `validate` letter and returns round `status`.
  """

  @spec guess(p :: t, guess :: Guess.directive | Guess.t) :: result
  def guess(%Player{} = p, :human, :guess_last_word = _guess) do
    @human = p.type

    fn_run = fn ->
      guess = Strategy.last_word(p.strategy)
      round_info = Round.guess(p, guess)
      p = Round.update(p, round_info, guess)
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


  def guess(%Player{} = p, :human, {:guess_letter, l} = guess)
  when is_binary(l) do 

    @human = p.type

    fn_run = fn ->
  	  guess = Strategy.letter_in_most_common(p.strategy, letter)
      round_info = Round.guess(p, guess)
		  p = Round.update(p, round_info, guess)

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
  Method returns empty `Player`
  """

  @spec delete(t) :: t
  def delete(%Player{} = _p), do: %Player{}


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
