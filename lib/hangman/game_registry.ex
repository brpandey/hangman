defmodule Hangman.Game.Registry do

  alias Hangman.{Game, Game.Registry, Player}

  require Logger

  defstruct games: %{}, active_pids: %{}

  @moduledoc """
  Module implements a simple registry 
  containing a map of games and active_pids
  """
  
  @opaque t :: %__MODULE__{}  
  
  @type id :: String.t

  # CREATE

  @spec new :: t
  def new, do: %Registry{}

  # adds a new player key to registry recordkeeping

  @spec add(t, Player.key) :: t
  def add(%Registry{} = registry, key) do

    # Destructuring bind
    {player_id, player_pid} = key

    # Check if this player_pid is already added 
    # (e.g. from a previous game in a multiple game set)

    registry = 
      case Map.has_key?(registry.active_pids, player_pid) do
        true ->
          # Ensure the player id matches the pid -- sanity check
          ^player_id = Map.get(registry.active_pids, player_pid)
          registry
        false -> 
          # Add

          # Establish the link to the player pid in case we get a player crash    
          Process.link(player_pid)
        
          # Let's preserve the player pid to player id mapping
          
          # if we want to remove the player by pid
          # its easy to find the player id, so we can also remove the 
          # player game state if desired
          
          active_pids = Map.put(registry.active_pids, player_pid, player_id)
          
          # Update registry
          registry = Kernel.put_in(registry.active_pids, active_pids)
          
          # retrieve already loaded game state 
          # update player_pid field with pid
          registry = 
            case Map.get(registry.games, player_id) do
              nil -> 
                # We should have player game state, so error
                raise HangmanError, "Expecting to find player game, not found"
              game ->
                # First put pid value in player game state
                game = Kernel.put_in(game.player_pid, player_pid)
                
                # Put single game back into registry
                games = Map.put(registry.games, player_id, game)
                
                # Lastly, update registry
                Kernel.put_in(registry.games, games)
            end
      end

    registry
  end

  # READ


  # Helper to retrieve the player key given pid
  
  @spec key(t, pid) :: Player.key
  def key(%Registry{} = registry, pid) when is_pid(pid) do
    case Map.get(registry.active_pids, pid) do
      nil -> raise HangmanError, "Unable to generate key, pid not found"
      id_key -> {id_key, pid}
    end
  end
  
  # Helper to retrieve the player player's game state

  @spec game(t, Player.key) :: Game.t
  def game(%Registry{} = registry, key) do

    # Retrieve player game state

    # De-bind
    {player_id, player_pid} = key

    # Ensure this player player is active
    game = 
      case Map.get(registry.active_pids, player_pid) do
        ^player_id ->
          # We have an active match
          # Retrieve game state from registry
          # Pattern match that we are returning a Game.t
          %Game{} = Map.get(registry.games, player_id)
        
        _ -> 
          # Player id not active, return empty game
          %Game{}
      end
    
    game
  end


  # UPDATE

  # Update game state
  # Returns updated registry


  # Since we don't have the full Player.key, 
  # Just use String.t id instead, this is invoked
  # for load_game(s) and init

  @spec update(t, id | Player.key, Game.t) :: t
  def update(%Registry{} = registry, key, game) when is_binary(key) do
    do_update(registry, key, game)
  end

  def update(%Registry{} = registry, key, game) when is_tuple(key) do

    # De-bind
    {player_id, _player_pid} = key
    do_update(registry, player_id, game)
  end

  defp do_update(%Registry{} = registry, key, game) when is_binary(key) do

    # Put game state into registry games map
    games = Map.put(registry.games, key, game)
    
    # Update registry
    registry = Kernel.put_in(registry.games, games)
    
    registry
  end


  # DELETE

  # remove player pid from active pid list

  @spec remove(t, Player.key, atom) :: t
  def remove(%Registry{} = registry, :actives, {player_id, player_pid} = _key)
  when is_binary(player_id) and is_pid(player_pid) do

    Logger.debug("About to remove player pid from active list")

    registry = 
      case Map.get(registry.active_pids, player_pid) do
        nil -> 
          # Flag as error if we can't find player pid in our system
          # something is weird
          raise HangmanError, "Can't remove a player pid that doesn't exist"
        ^player_id -> 
          # Match against player id value
          # First, remove pid from active_pids mapping
          active_pids = Map.delete(registry.active_pids, player_pid)
          registry = Kernel.put_in(registry.active_pids, active_pids)
          registry
        _ ->
          # We have the pid but it has a different id_key! flag error
          raise HangmanError, "Player pid found, but different Player id. Strange!"
          
      end
    
    # unlink last, now that we've removed from recordkeeping
    Process.unlink player_pid

    registry
  end

  def remove(%Registry{} = registry, :games, {player_id, _player_pid} = _key)
  when is_binary(player_id) do

    Logger.debug("About to remove player state from games")

    # Remove game state from registry
    # if it isn't there, raise error

    case Map.has_key?(registry.games, player_id) do
      false -> raise HangmanError, "Can't remove game state that doesn't exist"
      true -> 
        games = Map.delete(registry.games, player_id)
        registry = Kernel.put_in(registry.games, games)
    end
  end

end
