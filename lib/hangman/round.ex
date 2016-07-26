defmodule Hangman.Round do
  @moduledoc """
  Module provides access to game round functions.

  `Round` represents the time period in the `Hangman` game which 
  consists of a repetitive sequence of word set reduction, guess assistance and
  guess actions. It works in conjuction with `Strategy` and 
  `Game.Server` to orchestrate actual `round` game play.

  When playing a `Hangman` game, we first setup our round, which involves 
  obtaining the secret word length from the game server.  Next, we
  take steps to reduce the possible `Hangman` words set to narrow our 
  word choices.  From there on we choose the best letter to guess given
  the knowledge we have of our words data set.  If we are a `:human`, we
  are given letter choices to pick, and if we are a `:robot`, we trust our
  friend `Strategy`. After a guess is made either by `:human` or `:robot` we
  update our round recordkeeping structures with the guess results and proceed
  for the next round -- to do it all over again.

  Basic `Round` functionality includes `setup/4`, `guess/2`, 
  `transition/1`, `status/1`.

  We invoke setup before a guess.  Transition is used after a single game over 
  to determine if we transition to a new game or games over.
  """

  alias Hangman.{Round, Game, Guess, Pass, Player, Reduction, Letter.Strategy}

  defstruct id: "", num: 0, game_num: 0, context: nil,
  guess: {}, result_code: nil, status_code: nil, status_text: "", pattern: "",
  pid: nil, game_pid: nil, event_pid: nil
  
  @type t :: %__MODULE__{}
  @type code :: :correct_letter | :incorrect_letter | :incorrect_word
  @type result :: {code, status :: String.t}
  @type key :: {id :: String.t, client_pid :: pid} # Used as game key

  @typedoc """
  Sum type used to understand prior `guess` result
  """

  @type context ::  
  ({:game_start, secret_length :: pos_integer}) |
  ({:game_keep_guessing, :correct_letter, letter :: String.t, 
    pattern :: String.t, mystery_letter :: String.t}) |
  ({:game_keep_guessing, :incorrect_letter, letter :: String.t})
  

  # CREATE

  # Start the new game round

  def start(%Round{} = round) do
    
    if round.game_num == 0 do
      # Notify the event server that we've started playing hangman
      Player.Events.notify_start(round.event_pid, round.id)

      # update the passed in round
      %Round{ round | game_num: round.game_num + 1}
    else
      # create a new round with some leftover data from passed in round
      %Round{ id: round.id, pid: round.pid, game_num: round.game_num + 1, 
              game_pid: round.game_pid, event_pid: round.event_pid }
    end
  end
  
  # READ

  def reduce_context_key(%Round{} = round) do
    {round.id, round.game_num, round.num + 1}
  end

  def game_context_key(%Round{} = round) do
    {round.id, {round.id, round.pid}, round.game_num, round.num + 1, 
     round.game_pid, round.event_pid}
  end


  @doc """
  Returns `round` status tuple
  """

  @spec status(t) :: result
  def status(%Round{} = round) do
    {round.status_code, round.status_text}
  end

  # UPDATE
  
  # Setup the game play round

  @doc """
  Sets up game play `round`

  For game start stage, retrieves secret length from game server
  uses secret length to filter possible `Hangman` words from `Pass.Cache` server

  On start and subsequent rounds, also generates a reduce key based on the result of the
  last guess to filter possible `Hangman` words from `Pass.Cache` server
  """

  @spec setup(Round.t, List.t, Game.code, (Map.t -> Strategy.t) ) :: Round.t

  # setup routines as arranged by game status codes

  def setup(%Round{} = round, [], :game_start, fn_updater) do
    {round, pass_info} = round 
    |> do_setup(:game_server) 
    |> do_setup([], :reduction_pass)

    updater_result = fn_updater.(pass_info)

    {round, updater_result}
  end

  def setup(%Round{} = round, exclusion, :game_keep_guessing, fn_updater) do
    {round, pass_info} = do_setup(round, exclusion, :reduction_pass)
    updater_result = fn_updater.(pass_info)

    {round, updater_result}
  end

  # private setup routines as arranged by the type of setup

  defp do_setup(%Round{} = round, :game_server) do
    {name, key, game_no, _seq_no, game_pid, event_pid} = 
      Round.game_context_key(round)

    # Initiate the game and grab the secret length
    {^name, :secret_length, secret_length, status_text} =
      Game.Server.initiate_and_length(game_pid, key)
    
    Player.Events.notify_length(event_pid, {name, game_no, secret_length})

    # Quick assert
    true = is_number(secret_length) and secret_length > 0
    
    round = %Round{ round | status_code: :game_start, 
                   status_text: status_text, 
                   context: {:game_start, secret_length}}

    round
  end


  defp do_setup(%Round{} = round, exclusion, :reduction_pass) do
    
    # Generate the word filter options for the words reduction engine
    ctx = round.context

    reduce_key = ctx |> Reduction.Options.reduce_key(exclusion)
    match_key = ctx |> Kernel.elem(0)

    pass_key = Round.reduce_context_key(round)

    # Filter the engine hangman word set
    {^pass_key, pass_info} = 
      Pass.Cache.get({:pass, match_key}, pass_key, reduce_key)

    {round, pass_info}
  end


  @doc """
  Issues a client `guess` (either `letter` or `word`) against `Game.Server`.
  Notifies player `events` of guess `results`.

  Returns received `round` data
  """

  @spec guess(t, Guess.t) :: t
  def guess(%Round{} = round, 
            guess = {id, value}) 
  when id in [:guess_letter, :guess_word] and is_binary(value) do
    
    {id, player_key, game_no, round_num, game_pid, event_pid} = 
      Round.game_context_key(round)
    

    %{id: ^id, result: result, code: code, 
      pattern: pattern, text: text, summary: []} =
      Game.Server.guess(game_pid, player_key, guess)
    
    Player.Events.notify_guess(event_pid, guess,
                               {id, game_no})
    
    Player.Events.notify_status(event_pid,
                                {id, game_no, round_num, text})
    
    round = %Round{num: round_num,
                   guess: guess, result_code: result, 
                   status_code: code, pattern: pattern, 
                   status_text: text}

    # Compute round context for the next round
    round = Kernel.put_in(round.context, context(round))

    round

  end

  # Specifies steps for end of single game round 
  # transitions to either a :game_start or :games_over

  @spec transition(t) :: Map.t
  def transition(%Round{} = round) do

    true = round.status_code in [:game_won, :game_lost]

    {id, player_key, _, _, game_pid, _} = 
      Round.game_context_key(round)

    %{id: ^id, code: status_code, summary: summary_code} = 
      Game.Server.status(game_pid, player_key)

    round = Kernel.put_in(round.status_code, status_code)

    if status_code == :games_over do
      process_summary(round, summary_code) 
    else
      round
    end

    round
  end

  # Private
  # Helpers

  # If games are over, process games summary

  defp process_summary(%Round{} = round, summary_code) 
  when is_list(summary_code) do

    round =
    if (summary_code != "" and summary_code != [] and
        List.first(summary_code) == {:status, :games_over}) do
      
      summary = text_summary(summary_code)
      Player.Events.notify_games_over(round.event_pid, round.id, summary)
      
      Kernel.put_in(round.status_text, summary)
    end
    
    round
  end


  @docp """
  Returns `game` summary as a string.  Includes `number` of games played, `average` 
  score per game, per game `score`.
  """

  @spec text_summary(Game.summary) :: String.t
  defp text_summary(args) when is_list(args) and is_tuple(Kernel.hd(args)) do
    
    {:ok, avg} = Keyword.fetch(args, :average_score)
    {:ok, games} = Keyword.fetch(args, :games)
    {:ok, scores} = Keyword.fetch(args, :results)

    results = Enum.reduce(scores, "",  fn {k,v}, acc -> 
      acc <> " (#{k}: #{v})"  end)
      
    "Game Over! Average Score: #{avg}, " 
    <> "# Games: #{games}, Scores: #{results}"
  end


  # Returns round relevant data parameters

  @docp """
  Returns round `context` based on results of `last guess`
  """

  @spec context(t) :: context | no_return
  defp context(%Round{} = round) do
    case round.result_code do
      :correct_letter -> 
        {:guess_letter, letter} = round.guess

        {:game_keep_guessing, :correct_letter, letter, 
            round.pattern, Game.mystery_letter}

      :incorrect_letter -> 
        {:guess_letter, letter} = round.guess

        {:game_keep_guessing, :incorrect_letter, letter}

      :incorrect_word ->
        {:game_keep_guessing, :incorrect_letter, " "}

      true ->
        raise HangmanError, "Unknown round result"
    end
  end

  # EXTRA
  # Returns player information 
  @spec info(t) :: Keyword.t
  def info(%Round{} = round) do
    
    guess = 
      case round.guess do
        {} -> ""
        {_atom, token} -> token
      end
    
    round_info = [
        no: round.num,
        guess: guess,
        guess_result: round.result_code,
        round_code: round.status_code,
        round_status: round.status_text,
        pattern: round.pattern
    ]
    
    _info = [
      id: round.id,
      round_no: round.num,
      game_pid: round.game_pid,
      event_pid: round.event_pid,
      round_data: round_info
    ]
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Round.info(t), opts)
      concat ["#Round<", info, ">"]
    end
  end


end
