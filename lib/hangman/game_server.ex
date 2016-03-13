defmodule Game.Server do
  use GenServer
  
  defstruct games: %{}, active_pids: %{}
  
  require Logger
  
  @moduledoc """
  Module implements `Hangman` `Game` server using `GenServer`.
  Wraps `Game` abstraction as server state.  Runs 
  each game play one at a time. Handles multiple games concurrently.

  Interacts with client player through public interface and
  maintains game state
  """
  
  @type id :: String.t

  @opaque t :: %__MODULE__{}  

  @vsn "0"
  @name __MODULE__

  @max_wrong 5
  
  #####
  # External API
  
  
  @doc """
  Start public interface method with `secret(s)`
  """
  
  @spec start_link(id, (String.t | [String.t]), 
                   pos_integer) :: {:ok, pid}
  def start_link(id_key, secret, max_wrong \\ @max_wrong) do
    Logger.info "Starting Hangman Game Server"

    initial_game = Game.load(id_key, secret, max_wrong)
    options = [name: via_tuple(id_key)] #,  debug: [:trace]]

    # Store newly loaded, first player client game for this server process
    # into internal games map, and update state

    state = update(%Game.Server{}, id_key, initial_game)
    
    GenServer.start_link(@name, state, options)
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
  
  @spec load(pid, id, (String.t | [String.t]), pos_integer) :: :ok
  def load(game_pid, id_key, secret, max_wrong \\ @max_wrong)
  
  def load(game_pid, id_key, secret, max_wrong) when is_binary(secret) do
    GenServer.cast game_pid, {:load_game, id_key, secret, max_wrong}
  end
  
  def load(game_pid, id_key, secrets, max_wrong) when is_list(secrets) do
    GenServer.cast game_pid, {:load_games, id_key, secrets, max_wrong}
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
    the `:correct_word` data tuple along with game info
    If incorrect, returns the :incorrect_word data tuple with game info
    
  """
  
  @spec guess(pid, Player.key, Guess.t) :: tuple
  def guess(game_pid, key, guess = {:guess_letter, letter})
  when is_binary(letter) do
    GenServer.call game_pid, {guess, key}
  end
  
  def guess(game_pid, key, guess = {:guess_word, word})
  when is_binary(word) do
    GenServer.call game_pid, {guess, key}
  end
  
  @doc """
  Retrieves `Game` status data
  """
  
  @spec status(pid, Player.key) :: tuple
  def status(game_pid, key) do
    GenServer.call game_pid, {:game_status, key}
  end
  
  @doc """
  Initiates link with client and return secret length
  Retrieves `Game` secret length
  """
  
  @spec initiate_and_length(pid, Player.key) :: tuple
  def initiate_and_length(game_pid, key) do
    GenServer.call game_pid, {:initiate_and_length, key}
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
  
  #@callback init(t) :: tuple
  def init(state) do
    # Trap client exits
    Process.flag(:trap_exit, true)
    {:ok, state}
  end
  
  @docp """
  Loads a new `Game`
  """
  
#  @callback handle_cast(tuple, t) :: tuple
  def handle_cast({:load_game, id_key, secret, max_wrong}, state) do
    game = Game.load(id_key, secret, max_wrong)

    state = update(state, id_key, game)

    Logger.debug("load_game, Game.Server: #{inspect state}")
    
    {:noreply, state}
  end
  
  @docp """
  Loads a set of games
  """
  
#  @callback handle_cast(tuple, t) :: tuple  
  def handle_cast({:load_games, id_key, secret, max_wrong}, state) do
    game = Game.load(id_key, secret, max_wrong)

    state = update(state, id_key, game)

    Logger.debug("load_game, Game.Server: #{inspect state}")
    
    { :noreply, state }
  end
  
  
  @docp """
  {:guess_letter, letter}
  Guess the specified letter and update the pattern state accordingly

  Returns result data tuple
  """
  
#  @callback handle_call({Guess.t, Player.key}, tuple, t) :: tuple
  def handle_call({guess = {:guess_letter, _letter}, key}, _from, 
                  state) do

    # Retrieve client game state

    # Retrieve client game
    game = game(state, key)
    
    {game, result} = Game.guess(game, guess)

    # Update server state with updated game state
    state = update(state, key, game)

    Logger.debug("guess letter, Game.Server: #{inspect state}")
    
    { :reply, result, state }
  end
  
  @docp """
  {:guess_word, word}
  Guess the specified word and update the pattern state accordingly
  
  Returns result data tuple
  """
  
#  @callback handle_call(Guess.t, tuple, t) :: tuple
  def handle_call({guess = {:guess_word, _word}, key}, _from, 
                  state) do
    
    # Retrieve client game
    game = game(state, key)

    {game, result} = Game.guess(game, guess)

    # Update server state with updated game state
    state = update(state, key, game)

    Logger.debug("guess word, Game.Server: #{inspect state}")

    { :reply, result, state }
  end
  

  @docp """
  Returns the game status text
  """

#  @callback handle_call({Game.code, Player.key}, tuple, t) :: tuple
  def handle_call({:game_status, key}, _from, state) do

    # Retrieve client game
    game = game(state, key)

    { :reply, Game.status(game), state }
  end
  
  @docp """
  Returns the hangman secret length
  """
  
#  @callback handle_call({:atom, Player.key}, tuple, t) :: tuple
  def handle_call({:initiate_and_length, key}, _from, state) do

    # initiate the player client add
    state = add(state, key)

    # Retrieve game
    game = game(state, key)

    # Game.status is read only
    {_, _, status_text} = Game.status(game)
    length = String.length(game.secret)
    
    # Let's piggyback the round status text with the secret length value
    
    { :reply, {game.id, :secret_length, length, status_text}, state }
  end
  
  @docp """
  Stops the server is a normal graceful way
  """
  
#  @callback handle_call(:atom, tuple, t) :: tuple
  def handle_call(:stop, _from, state) do
    { :stop, :normal, {:ok, state.id}, state }
  end

  @docp """
  Handles client pid down
  """

  #@callback handle_info(term, tuple, t) :: tuple

  def handle_info({:EXIT, _pid, :normal} = msg, _from, state) do
    IO.puts "In Game.Server handle info, received EXIT msg: #{inspect msg}"
    { :noreply, state }
  end


  def handle_info({:EXIT, _pid, _reason} = msg, _from, state) do
    IO.puts "In Game.Server handle info, received EXIT msg: #{inspect msg}"
    { :noreply, state }
  end

  # Generic
  def handle_info(msg, _from, state) do
    IO.puts "In Game.Server handle info, msg is #{inspect msg}"
    { :noreply, state }
  end


  
  @docp """
  Terminates the `game` server
  No special cleanup other than refreshing the state
  """
  
#  @callback terminate(term, term) :: :ok
  def terminate(_reason, _state) do
    Logger.info "Terminating Hangman Game Server"
    :ok
  end
  

  # PRIVATE HELPERS

  # CRUD Functionality for Game.Server Abstraction



  # CREATE

  # adds a new player client to game server recordkeeping

  @spec add(t, Player.key) :: t
  defp add(state, key) do

    # Destructuring bind
    {client_id, client_pid} = key

    # Check if this client_pid is already added 
    # (e.g. from a previous game in a multiple game set)

    case Map.has_key?(state.active_pids, client_pid) do
      true ->
        # Ensure the client id matches the pid -- sanity check
        ^client_id = Map.get(state.active_pids, client_pid)

      false -> 
        # Add

        # Establish the link to the client pid in case we get a client crash    
        Process.link(client_pid)
        
        # Let's preserve the client pid to client id mapping

        # if we want to remove the client by pid
        # its easy to find the client id, so we can also remove the 
        # client game state if desired
        
        active_pids = Map.put(state.active_pids, client_pid, client_id)
        
        # Update state
        state = Kernel.put_in(state.active_pids, active_pids)

        # retrieve already loaded game state 
        # update client_pid field with pid
        case Map.get(state.games, client_id) do
          nil -> 
            # We should have client game state, so error
            raise HangmanError, "Expecting to find client game, not found"
          game ->
            # First put pid value in client game state
            game = Kernel.put_in(game.client_pid, client_pid)

            # Put single client game back into server games state
            games = Map.put(state.games, client_id, game)
            
            # Lastly, update server state
            state = Kernel.put_in(state.games, games)
        end
    end

    state
  end

  # READ

  # Helper to retrieve the player client's game state

  @spec game(t, Player.key) :: Game.t
  defp game(state, key) do

    # Retrieve client game state

    # De-bind
    {client_id, client_pid} = key

    # Ensure this player client is active
    game = 
      case Map.get(state.active_pids, client_pid) do
        ^client_id ->
          # We have an active match
          # Retrieve client game state from server clients map
          # Pattern match that we are returning a Game.t
          %Game{} = Map.get(state.games, client_id)
        
        _ -> 
          # Client id not active, return empty game
          %Game{}
      end


    
    game
  end


  # UPDATE

  # Helper to update client game state
  # Returns updated server state


  # Since we don't have the full Player.key, 
  # Just use String.t id instead, this is invoked
  # for load_game(s) and init

  @spec update(t, id | Player.key, Game.t) :: t
  defp update(state, key, game) when is_binary(key) do

    # Put game state into server state games map
    games = Map.put(state.games, key, game)
    
    # Update state
    state = Kernel.put_in(state.games, games)

    state
  end

  defp update(state, key, game) when is_tuple(key) do

    # De-bind
    {client_id, _client_pid} = key

    # If we are given an empty game -- we know we have game over
    # So don't update -- leave the game state as is

    case Game.empty?(game) do
      false ->
        # Put game state into server state games map
        games = Map.put(state.games, client_id, game)
        
        # Update state
        state = Kernel.put_in(state.games, games)

      true ->
        # remove player from active
        Logger.debug("About to remove player pid from active list")
        state = remove(key, state)
    end
    
    state
  end


  # DELETE

  # remove client pid from active pid list

  @spec remove(Player.key, t) :: t
  defp remove({client_id, client_pid} = _key, state)
  when is_binary(client_id) and is_pid(client_pid) do

    # Destructuring bind

    case Map.get(state.active_pids, client_pid) do
      nil -> 
        # Flag as error if we can't find client pid in our system
        # something is weird
        raise HangmanError, "Can't remove a client pid that doesn't exist"
      ^client_id -> 
        # Match against client id value
        # First, remove pid from active_pids mapping
        active_pids = Map.delete(state.active_pids, client_pid)
        state = Kernel.put_in(state.active_pids, active_pids)

        ''' 
        Leave game state there... until process terminates
        # Second, Remove client game state from server games recordkeeping
        # if it isn't there, raise error again
        case Map.has_key?(state.games, client_id) do
          false -> raise HangmanError, "Can't remove game state that doesn't exist"
          true -> 
            games = Map.delete(state.games, client_id)
            state = Kernel.put_in(state.games, games)
        end
        '''
      _ ->
        # We have the pid but it has a different id_key! flag error
        raise HangmanError, "Client pid found, but different Client id. Strange!"
        
    end

    # unlink last, now that we've removed from recordkeeping
    Process.unlink client_pid

    state
  end
end
