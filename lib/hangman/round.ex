defmodule Hangman.Round do
  @moduledoc """
  Module provides access to game round functions.

  `Round` represents the time period in the `Hangman` game which 
  consists of setup steps: word set reduction, guess assistance. 

  It works in conjuction with `Strategy` and `Game.Server` to 
  orchestrate actual `round` game play through guess actions.

  A) When playing a new `Hangman` game, we first register our round, 
  which involves obtaining the secret word length from the game server.  

  B) Next, we take steps to reduce the possible `Hangman` words set to narrow our 
  word choices.  

  From there on we choose the best letter to guess given
  the knowledge we have of our words data set.  If we are a `:human`, we
  are given letter choices to pick, and if we are a `:robot`, we trust our
  friend `Strategy`. 

  C) After a guess is made either by `:human` or `:robot` we
  update our round recordkeeping structures with the guess results and proceed
  for the next round -- to do it all over again minus the init stage.

  Basic `Round` functionality includes `register/1`, `setup/2`, `guess/2`, 
  `transition/1`, `status/1`.

  We always invoke setup before a guess, to properly setup the new words state.  

  Transition is used after a single game over 
  to determine if we transition to a new game or games over.
  """

  alias Hangman.{Round, Guess, Reduction}
  alias Hangman.Game.Server, as: Game   # single place to switch to Game.Server.Stub
  alias Hangman.Pass, as: Pass   # single place to switch to Pass.Stub
  require Logger


  defstruct id: "", num: 0, game_num: 0, context: nil,
  guess: {}, result_code: nil, status_code: nil, status_text: "", pattern: "",
  pid: nil, game_pid: nil
  
  @opaque t :: %__MODULE__{}
  @type result_code :: :correct_letter | :incorrect_letter | :incorrect_word | :correct_word

  @type key :: {id :: (String.t | tuple), 
                game_num :: non_neg_integer,
                round_num :: non_neg_integer} # Used as round key

  @typedoc """
  Sum type used to understand prior `guess` result
  """

  @type context :: {:start, non_neg_integer} 
  | {:guessing, :correct_letter, String.t, pattern :: String.t, mystery_letter :: String.t} 
  | {:guessing, :incorrect_letter | :incorrect_word, String.t} 
  | {:won, :correct_word, String.t}
  
                    
  @mystery_letter "-"


  # CREATE

  @spec new((String.t | tuple), pid) :: Round.t
  def new(name, game_pid) when 
  (is_binary(name) or is_tuple(name)) and is_pid(game_pid) do
    %Round{ id: name, pid: self(), game_pid: game_pid }
  end


  @doc """
  Register the round with the start of a new game.  Retrieves the 
  secret length from the game server and creates a process link to the 
  game server via the register call.  

  Eventually the secret length is used to filter possible `Hangman` words 
  from `Pass.Cache` server on the next round setup.
  """

  @spec register(t) :: t
  def register(%Round{} = round) do
    
    round = 
      case round.game_num do
        0 -> round
        _ ->
          # create a new round with some leftover data from passed in round
          %Round{ id: round.id, pid: round.pid, game_pid: round.game_pid }
      end

    # Further update round
    round = %{ round | num: 0, 
               game_num: round.game_num + 1, 
               status_code: :start }
    
    {player_key, round_key, game_pid} = game_context_key(round)

    # Register the client with the game server and set the context
    %{key: ^round_key, code: status_code, data: data, text: status_text} =
      Game.register(game_pid, player_key, round_key)    

    context = if status_code == :finished do nil else build_context(round, data) end

    %{ round | status_code: status_code,
       status_text: status_text, 
       context: context }
    
  end
  
  # READ

  @doc """
  Returns `round` status tuple
  """

  @spec status(t) :: {Game.code, String.t}
  def status(%Round{} = round), do: {round.status_code, round.status_text}

  # UPDATE
  
  # Setup the game play round

  @doc """
  Sets up game play `round`

  Generates a reduce key based on the result of the
  last guess or secret length to filter possible 
  `Hangman` words from `Pass.Cache` server

  Returns round and pass data metadata
  """

  @spec setup(t, Enumerable.t) :: {t, Pass.t}
  def setup(%Round{} = round, exclusion) do

    # since we're at the start of a new round increment round num
    round = Kernel.put_in(round.num, round.num + 1)

    # Generate the word filter options for the words reduction engine
    reduce_key = round.context |> Reduction.Options.reduce_key(exclusion)
    match_key = round.context |> Kernel.elem(0)
    pass_key = round_key(round)

    # Filter the hangman word set, grab the result of the pass
    {^pass_key, pass_info} = 
      Pass.result(match_key, pass_key, reduce_key)

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
      Game.guess(game_pid, player_key, round_key, guess)
    
    round = %{round | guess: guess, result_code: result_code, 
              status_code: status_code, pattern: pattern, 
              status_text: status_text}

    # Compute round context for the next round
    round = Kernel.put_in(round.context, build_context(round))

    round

  end

  @doc """
  Specifies steps for the end of a single game. 
  Transitions to either a :start or :finished
  depending on if there are games left to play
  """

  @spec transition(t) :: t
  def transition(%Round{} = round) do

    true = round.status_code in [:won, :lost]

    # invoke pass clean up routine, so that we purge pass table of 
    # last pass data
    round |> increment_key |> Pass.delete

    {player_key, round_key, game_pid} = game_context_key(round)

    %{key: ^round_key, code: status_code} = status =
      Game.status(game_pid, player_key, round_key)

    round = Kernel.put_in(round.status_code, status_code)

    # Handle the special case if we are starting a new game
    # return the previous games results
    status_text = 
      case status_code do
        :start -> 
          %{text: text} = Map.get(status, :previous)
          text
        _ -> Map.get(status, :text)
      end
    
    round = Kernel.put_in(round.status_text, status_text)

    round
  end

  # Returns round `context` based on results of `last guess`

  @spec build_context(t, none | non_neg_integer) :: context | no_return
  defp build_context(%Round{} = round, data \\ 0) do
    case round.result_code do
      nil -> {:start, data}

      :correct_letter -> 
        {:guess_letter, letter} = round.guess
        {:guessing, :correct_letter, letter, round.pattern, @mystery_letter}

      :incorrect_letter -> 
        {:guess_letter, letter} = round.guess
        {:guessing, :incorrect_letter, letter}

      :incorrect_word ->
        {:guess_word, word} = round.guess
        {:guessing, :incorrect_word, word}

      :correct_word -> 
        {:guess_word, word} = round.guess
        {:won, :correct_word, word}
      
      true ->
        raise HangmanError, "Unknown round result"
    end
  end


  @doc "Returns round tuple key"

  @spec round_key(t) :: key
  def round_key(%Round{} = round), do: {round.id, round.game_num, round.num}

  @spec increment_key(t) :: key
  defp increment_key(%Round{} = round), do:  {round.id, round.game_num, round.num + 1}

  @spec player_key(t) :: tuple
  defp player_key(%Round{} = round), do: {round.id, round.pid}

  @spec game_context_key(t) :: {tuple, key, pid}
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
