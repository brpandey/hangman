defmodule Hangman.Game.Server do
  use GenServer
    
  require Logger

  alias Hangman.{Game, Game.Event, Guess, Player, Round, Simple.Registry}
  
  @moduledoc """
  Module handles `Hangman` `Game` serving to multiple clients.  
  Each player's active game state is maintained, until the player 
  process exits.
  
  In the event the player aborts abnormally, the player's game state
  is maintained but removed from active status.  Subsequent player access
  will find the game in the :abort state and the game will check if there
  are any games left to play properly.  If so, game playing continues regularly,
  else, the game is properly ended with the game over results.

  NOTE: The server runs each game one at a time and handles support for 
  multiple games concurrently but is currently not harnessed by the 
  `Game.Pid.Cache.Server` for initial simplicity purposes and therefore
  not presently utilized.
  """
  
  @type id :: Player.id

  @vsn "0"

  @max_wrong 5
  
  #####
  # External API
  

  @doc """
  Start public interface method with `secret(s)`
  """
  
  @spec start_link(id, (String.t | [String.t]), 
                   pos_integer) :: GenServer.on_start
  def start_link(id_key, secret, max_wrong \\ @max_wrong) do


    game = Game.new(id_key, secret, max_wrong)

    # Store newly loaded, game into the game server registry

    registry = Registry.new |> Registry.update(id_key, game)

    options = [name: via_tuple(id_key)] #,  debug: [:trace]]
    
    GenServer.start_link(__MODULE__, registry, options)
  end
  

  @doc """
  Routine returns game server `pid` from process registry using `gproc`
  If not found, returns `:undefined`
  """
  
  @spec whereis(id) :: pid | :atom
  def whereis(id_key) do
    :gproc.whereis_name({:n, :l, {:hangman_server, id_key}})
  end
  
  # Used to register / lookup process in process registry via gproc
  @spec via_tuple(id) :: tuple
  defp via_tuple(id_key) do
    {:via, :gproc, {:n, :l, {:hangman_server, id_key}}}
  end
  
  @doc """
  Loads new `game` into server process state. 
  Used primarily by `Game.Pid.Cache`
  """
  
  @spec setup(pid, id, (String.t | [String.t]), pos_integer) :: :ok
  def setup(game_pid, id_key, secret, max_wrong \\ @max_wrong)
  
  def setup(game_pid, id_key, secret, max_wrong) when is_binary(secret) do
    GenServer.cast game_pid, {:setup, id_key, secret, max_wrong}
  end
  
  def setup(game_pid, id_key, secrets, max_wrong) when is_list(secrets) do
    GenServer.cast game_pid, {:setup, id_key, secrets, max_wrong}
  end
  
  @doc """
  Issues guess `letter` or `word` request, returns guess `result`

  Internally, runs `guess` against game `secret`. Updates `Hangman` pattern, status, and
  other game recordkeeping structures.

  Guesses follow two types

    * `{:guess_letter, letter}` -   If correct, 
    returns the `:correct_letter` data tuple along with game info
    otherwise, returns the `:incorrect_letter` data tuple along with game info

    * `{:guess_word, word}` -   If correct, returns 
    the `:correct_word` data tuple along with game info.
    If incorrect, returns the :incorrect_word data tuple with game info
    
  """
  
  @spec guess(pid, Player.key, Round.key, Guess.t) :: tuple
  def guess(game_pid, player_key, round_key, guess = {:guess_letter, letter})
  when is_binary(letter) do
    GenServer.call game_pid, {guess, player_key, round_key}
  end
  
  def guess(game_pid, player_key, round_key, guess = {:guess_word, word})
  when is_binary(word) do
    GenServer.call game_pid, {guess, player_key, round_key}
  end
  
  @doc """
  Retrieves `Game` status data
  """
  
  @spec status(pid, Player.key, Round.key) :: tuple
  def status(game_pid, player_key, round_key) do
    GenServer.call game_pid, {:status, player_key, round_key}
  end
  
  @doc """
  Initiates link with client and returns `Game` secret length
  """
  
  @spec register(pid, Player.key, Round.key) :: tuple
  def register(game_pid, player_key, round_key) do
    GenServer.call game_pid, {:register, player_key, round_key}
  end
  
  '''
  def another_game(secret, max_wrong \\ 5) when is_binary(secret) do
  GenServer.cast @name, {:another_game, secret, max_wrong}
  end
  '''
  
  @doc """
  Issues request to stop `GenServer`
  """
  
  @spec stop(pid) :: tuple
  def stop(game_pid) do
    GenServer.call game_pid, :stop
  end
  
  #####
  # GenServer implementation
  
  @docp """
  GenServer callback to initalize server process
  """
  
  @callback init(term) :: tuple
  def init(state) do
    Logger.info "Starting Hangman Game Server #{inspect self}"
    {:ok, state}
  end
  
  @docp """
  Loads a new `Game`
  """
  
  @callback handle_cast(tuple, Registry.t) :: tuple
  def handle_cast({:setup, id_key, secret, max_wrong}, state) do
    game = Game.new(id_key, secret, max_wrong)
    state = Registry.update(state, id_key, game)

    {:noreply, state}
  end
  
  @docp """
  Registers pid and returns the hangman secret length
  """
  
  @callback handle_call({:atom, Player.key, Round.key}, tuple, Registry.t) :: tuple
  def handle_call({:register, {_, pid_key} = player_key, round_key}, _from, state) do

    # add the player key to the registry
    state = Registry.add_key(state, player_key)

    # Monitor process
    Process.monitor(pid_key)

    # Retrieve game
    game = Registry.value(state, player_key)

    {game, %{code: status_code, text: status_text}}  = Game.status(game)

    # Update server state with updated game state
    state = Registry.update(state, player_key, game)

    {id, game_num, _round_num} = round_key

    data = 
      case status_code do
        code when code in [:start, :guessing] ->
          data = Game.secret_length(game)    
          Event.Manager.async_notify({:register, id, {game_num, data}})
          data
        :finished ->
          data = 0
          Event.Manager.async_notify({:finished, id, status_text})
          data
      end

    # Let's piggyback the round status text with the secret length value
    
    { :reply, %{key: round_key, code: status_code, data: data, text: status_text}, state }
  end

  
  @docp """
  {:guess_letter, letter}
  Guess the specified letter and update the pattern state accordingly

  Returns result data tuple
  """
  
  @callback handle_call({Guess.t, Player.key, Round.key}, tuple, Registry.t) 
  :: tuple
  def handle_call({guess = {:guess_letter, _letter}, player_key, round_key}, _from, 
                  state) do

    # Retrieve client game state
    game = Registry.value(state, player_key)
    
    {game, result} = Game.guess(game, guess)

    # Update server state with updated game state
    state = Registry.update(state, player_key, game)

    {id, game_num, round_num} = round_key

    %{text: status_text} = result

    Event.Manager.async_notify({:guess, id, {guess, game_num}})
    Event.Manager.async_notify({:status, id, {game_num, round_num, status_text}})

    Logger.debug("guessed letter, Game.Server: #{inspect state}, self: #{inspect self}")
    
    result = result |> Map.put(:key, round_key)

    { :reply, result, state }
  end
  
  @docp """
  {:guess_word, word}
  Guess the specified word and update the pattern state accordingly
  
  Returns result data tuple
  """

  @callback handle_call({Guess.t, Player.key, Round.key}, tuple, Registry.t) 
  :: tuple  
  def handle_call({guess = {:guess_word, _word}, player_key, round_key}, _from, 
                  state) do
    
    # Retrieve client game
    game = Registry.value(state, player_key)

    {game, result} = Game.guess(game, guess)

    # Update server state with updated game state
    state = Registry.update(state, player_key, game)


    {id, game_num, round_num} = round_key

    %{text: status_text} = result

    Event.Manager.async_notify({:guess, id, {guess, game_num}})
    Event.Manager.async_notify({:status, id, {game_num, round_num, status_text}})

    Logger.debug("guessed word, Game.Server: #{inspect state}, self: #{inspect self}")

    result = result |> Map.put(:key, round_key)

    { :reply, result, state }
  end
  

  @docp """
  Returns the game status text
  """

  @callback handle_call({atom, Player.key, Round.key}, tuple, Registry.t) 
  :: tuple
  def handle_call({:status, player_key, round_key}, _from, state) do

    # Retrieve client game
    game = Registry.value(state, player_key)

    {game, result} = Game.status(game)

    state = Registry.update(state, player_key, game)

    %{code: status_code, text: status_text} = result
    {id, _game_num, _} = round_key

    # Notify event manager
    case status_code do
      :finished -> Event.Manager.async_notify({:finished, id, status_text})
      _ -> ""
    end

    result = result |> Map.put(:key, round_key)

    { :reply, result, state }
  end
  
  

  @docp """
  Stops the server in a normal graceful way
  """
  
#  @callback handle_call(:atom, tuple, Registry.t) :: tuple
  def handle_call(:stop, _from, state) do
    { :stop, :normal, {:ok, state.id}, state }
  end

  @docp """
  Handles client pid down
  """

  @docp """
  Handles state cleanup when player client process exits. 
  If normal exit, remove player from state. If not, keep player
  game state around to inspect and potentially for retry.
  """

  #@callback handle_info(term, tuple, Registry.t) :: tuple

  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do


    Logger.debug "In Game.Server handle info, received :DOWN normal msg, self: #{inspect self}"

    Process.demonitor(ref)

    # generate player key

    state =
      case Registry.key(state, pid) do
        nil -> state

        player_key ->
          # remove player from active keys and games
          # it was a normal exit, clean the state
          state = state 
          |> Registry.remove(:active, player_key)
          |> Registry.remove(:value, player_key)
      end
      

    Logger.debug(":DOWN :normal, #{inspect state}")

    { :noreply, state }
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do

    Logger.debug "In Game.Server handle info, received :DOWN msg, self: #{inspect self}, reason: #{inspect reason}"

    Process.demonitor(ref)
    
    # remove player key from active keys
    # keep the player state if we want to look at it, since
    # it was an abnormal exit

    state =
      # generate player key
      case Registry.key(state, pid) do
        nil -> state

        player_key ->
          game = Registry.value(state, player_key)

          # remove player from active keys and games
          # it was a normal exit, clean the state
          state = state |> Registry.remove(:active, player_key)

          # grab the game and tag it as aborted
          
          game = Game.abort(game)

          state = state |> Registry.update(player_key, game)
      end


    Logger.debug(":DOWN, #{inspect state}")
    { :noreply, state }
  end

  # Generic
  def handle_info(msg, state) do
    Logger.debug "In Game.Server handle info, msg is #{inspect msg}"
    { :noreply, state }
  end


  
  @docp """
  Terminates the `game` server
  No special cleanup other than refreshing the state
  """
  
#  @callback terminate(term, term) :: :ok
  def terminate(reason, _state) do
    Logger.info "Terminating Hangman Game Server reason: #{inspect reason}, #{inspect self}"
    :ok
  end
  
end
