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

  alias Hangman.{Round, Game, Guess, Pass, Reduction, Letter.Strategy}

  require Logger

  defstruct id: "", num: 0, game_num: 0, context: nil,
  guess: {}, result_code: nil, status_code: nil, status_text: "", pattern: "",
  pid: nil, game_pid: nil
  
  @type t :: %__MODULE__{}
  @type result_code :: :correct_letter | :incorrect_letter | :incorrect_word

  @type key :: {id :: String.t, 
                game_num :: integer,
                round_num :: integer} # Used as round key

  @typedoc """
  Sum type used to understand prior `guess` result
  """

  @type context ::  
  ({:game_start, secret_length :: pos_integer}) |
  ({:game_keep_guessing, :correct_letter, letter :: String.t, 
    pattern :: String.t, mystery_letter :: String.t}) |
  ({:game_keep_guessing, :incorrect_letter, letter :: String.t})
  

  # CREATE

  # Start the new game, first round

  def start(%Round{} = round) do
    
    round = 
      case round.game_num do
        0 ->
          # update the passed in round
          %Round{ round | game_num: round.game_num + 1, num: 0, pid: self(),
                  status_code: :game_start}
        _ ->
          # create a new round with some leftover data from passed in round
          %Round{ id: round.id, pid: round.pid, num: 0,
                  game_num: round.game_num + 1, status_code: :game_start,
                  game_pid: round.game_pid }
      end
    
    {player_key, round_key, game_pid} = game_context_key(round)

    Logger.info "About to register with game server, player_key is #{inspect player_key}"
    
    # Register the client with the game server and set the context
    %{key: ^round_key, code: status_code, data: data, text: status_text} =
      Game.Server.register(game_pid, player_key, round_key)
    

    context = if status_code == :games_over do nil else {:game_start, data} end

    %Round{ round | status_code: status_code, # was :game_start previously
            status_text: status_text, 
            context: context}
    
  end
  
  # READ

  @doc """
  Returns `round` status tuple
  """

  @spec status(t) :: {Game.code, String.t}
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

  @spec setup(Round.t, List.t, (Map.t -> Strategy.t) ) :: Round.t

  def setup(%Round{} = round, exclusion, fn_updater) do

    # since we're at the start of a new round increment round num
    round = Kernel.put_in(round.num, round.num + 1)

    {round, pass_info} = round |> do_reduction_setup(exclusion)
    updater_result = fn_updater.(pass_info)

    {round, updater_result}
  end


  defp do_reduction_setup(%Round{} = round, exclusion) do
    
    # Generate the word filter options for the words reduction engine
    reduce_key = round.context |> Reduction.Options.reduce_key(exclusion)
    match_key = round.context |> Kernel.elem(0)
    pass_key = round_key(round)

    # Filter the engine hangman word set
    {^pass_key, pass_info} = 
      Pass.Cache.get({:pass, match_key}, pass_key, reduce_key)

    {round, pass_info}
  end


  @doc """
  Issues a client `guess` (either `letter` or `word`) against `Game.Server`.

  Returns received `round` data
  """

  @spec guess(t, Guess.t) :: t
  def guess(%Round{} = round, guess = {id, value}) 
  when id in [:guess_letter, :guess_word] and is_binary(value) do
    
    {player_key, round_key, game_pid} = game_context_key(round)

    %{key: ^round_key, result: result_code, code: status_code, 
      pattern: pattern, text: status_text} =
      Game.Server.guess(game_pid, player_key, round_key, guess)
    
    round = %Round{round | guess: guess, result_code: result_code, 
                   status_code: status_code, pattern: pattern, 
                   status_text: status_text}

    # Compute round context for the next round
    round = Kernel.put_in(round.context, build_context(round))

    round

  end

  # Specifies steps for end of single game round 
  # transitions to either a :game_start or :games_over

  @spec transition(t) :: Map.t
  def transition(%Round{} = round) do

    true = round.status_code in [:game_won, :game_lost]

    {player_key, round_key, game_pid} = game_context_key(round)

    %{key: ^round_key, code: status_code} = status =
      Game.Server.status(game_pid, player_key, round_key)

    round = Kernel.put_in(round.status_code, status_code)

    # If text field not in map, return default value
    status_text = Map.get(status, :text, "Game transition")
    round = Kernel.put_in(round.status_text, status_text)

    round
  end


  # Returns round relevant data parameters

  @docp """
  Returns round `context` based on results of `last guess`
  """

  @spec build_context(t) :: context | no_return
  defp build_context(%Round{} = round) do
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

      :correct_word -> 
        {:guess_word, word} = round.guess
        {:game_won, :correct_word, word}
      

      true ->
        raise HangmanError, "Unknown round result"
    end
  end


  def round_key(%Round{} = round), do: {round.id, round.game_num, round.num}
  defp player_key(%Round{} = round), do: {round.id, round.pid}

  defp game_context_key(%Round{} = round) do
    pkey = player_key(round)
    rkey = round_key(round)
    {pkey, rkey, round.game_pid}
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
      game_num: round.game_num,
      round_num: round.num,
      guess: guess,
      guess_result: round.result_code,
      round_code: round.status_code,
      round_status: round.status_text,
      pattern: round.pattern,
      context: round.context
    ]
    
    _info = [
      id: round.id,
      pid: round.pid,
      game_pid: round.game_pid,
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
