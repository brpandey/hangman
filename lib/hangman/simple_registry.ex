defmodule Hangman.Simple.Registry do

  @moduledoc """
  Module implements a simple registry keeping track of active pids,
  active ids, and their process state values e.g. Player.t or Game.t

  Registry key is of type {String.t, pid}

  Host GenServers which call this module need to implement appropriate 
  handle_info routines when pid value exits normally or abnormally
  """

  alias Hangman.{Simple.Registry}

  require Logger

  # values map ids to values e.g. Player.t or Game.t
  # active_pids maps pids to ids
  # active ids maps ids to pids
  
  defstruct values: %{}, active_pids: %{}, active_ids: %{}


  @opaque t :: %__MODULE__{}  
  
  @type id :: String.t
  @type key :: {id, pid}

  # CREATE

  @spec new :: t
  def new, do: %Registry{}

  # adds a new key to registry recordkeeping

  @spec add_key(t, key) :: t
  def add_key(%Registry{} = registry, key) do

    registry = add(:active_pids, registry, key)
    registry = add(:active_ids, registry, key)

    registry
  end


  @spec add(atom, t, key) :: t
  defp add(:active_pids, %Registry{} = registry, key) do

    # Destructuring bind
    {id_key, pid_key} = key

    # Check if this pid_key is already added 

    case Map.has_key?(registry.active_pids, pid_key) do
      true ->
        # Ensure the  id matches the pid -- sanity check
        ^id_key = Map.get(registry.active_pids, pid_key)

        registry
      false -> 
        # Add
        
        # Establish the link to the pid in case we get a crash    
        Process.link(pid_key)
        
        # Let's preserve the pid to id mapping
        
        # if we want to remove the key by pid
        # its easy to find the id, so we can also remove the 
        # value state if desired
        
        active_pids = Map.put(registry.active_pids, pid_key, id_key)
        
        # Update registry
        registry = Kernel.put_in(registry.active_pids, active_pids)

        registry
    end
  end

  @spec add(atom, t, key) :: t
  defp add(:active_ids, %Registry{} = registry, key) do

    # Destructuring bind
    {id_key, pid_key} = key

    # Check if this pid_key is already added 

    case Map.has_key?(registry.active_ids, id_key) do
      true ->
        # Ensure the pid matches the id -- sanity check
        ^pid_key = Map.get(registry.active_ids, id_key)

        registry
      false -> 
        # Add
        
        # Let's preserve the id to pid mapping
        
        active_ids = Map.put(registry.active_ids, id_key, pid_key)
        
        # Update registry
        registry = Kernel.put_in(registry.active_ids, active_ids)

        registry
    end
  end


  # Helper to retrieve the key given pid or id
  
  @spec key(t, pid) :: key
  def key(%Registry{} = registry, pid) when is_pid(pid) do
    case Map.get(registry.active_pids, pid) do
      nil -> raise HangmanError, "Unable to retrieve key, pid not found"
      id_key -> {id_key, pid}
    end
  end

  @spec key(t, id) :: key
  def key(%Registry{} = registry, id) when is_binary(id) do
    case Map.get(registry.active_ids, id) do
      nil -> raise HangmanError, "Unable to retrieve key, id not found"
      pid_key -> {id, pid_key}
    end
  end

  
  # Helper to retrieve the value state given the key

  @spec value(t, key) :: any
  def value(%Registry{} = registry, key) when is_tuple(key) do

    # Retrieve value state

    # De-bind
    {id_key, pid_key} = key

    # Ensure this key is active
    value = 
      case Map.get(registry.active_pids, pid_key) do
        ^id_key ->
          # We have an active match
          # Retrieve value state from registry

          value = Map.get(registry.values, id_key)
        
        _ -> 
          # id not active, return nil value
          nil
      end
    
    value
  end


  # UPDATE

  # Update value state
  # Returns updated registry


  # Since we don't have the full key, 
  # Just use String.t id instead

  @spec update(t, id | key, any) :: t
  def update(%Registry{} = registry, key, value) when is_binary(key) do
    do_update(registry, key, value)
  end

  def update(%Registry{} = registry, key, value) when is_tuple(key) do

    # De-bind
    {id_key, _pid_key} = key
    do_update(registry, id_key, value)
  end

  defp do_update(%Registry{} = registry, key, value) when is_binary(key) do

    # Put value state into registry values map
    values = Map.put(registry.values, key, value)
    
    # Update registry
    registry = Kernel.put_in(registry.values, values)
    
    registry
  end


  # DELETE

  # remove pid from active pid list

  @spec remove(t, :atom, key) :: t


  def remove(%Registry{} = registry, :value, {id_key, _pid_key} = _key)
  when is_binary(id_key) do

    Logger.debug("About to remove state from values")

    # Remove value state from registry
    # if it isn't there, raise error

    case Map.has_key?(registry.values, id_key) do
      false -> raise HangmanError, "Can't remove value state that doesn't exist"
      true -> 
        values = Map.delete(registry.values, id_key)
        registry = Kernel.put_in(registry.values, values)
    end
  end

  def remove(%Registry{} = registry, :active, {id_key, pid_key} = key)
  when is_binary(id_key) and is_pid(pid_key) do

    registry |> do_remove(:active_pids, key) |> do_remove(:active_ids, key)
  end


  defp do_remove(%Registry{} = registry, :active_pids, {id_key, pid_key} = _key)
  when is_binary(id_key) and is_pid(pid_key) do

    Logger.debug("About to remove pid from active list")

    registry = 
      case Map.get(registry.active_pids, pid_key) do
        nil -> 
          # Flag as error if we can't find pid in our system
          # something is weird
          raise HangmanError, "Can't remove a pid that doesn't exist"
        ^id_key -> 
          # Match against id value
          # First, remove pid from active_pids mapping
          active_pids = Map.delete(registry.active_pids, pid_key)
          registry = Kernel.put_in(registry.active_pids, active_pids)
          registry
        _ ->
          # We have the pid but it has a different id_key! flag error
          raise HangmanError, "pid found, but different id. Strange!"
          
      end
    
    # unlink last, now that we've removed from recordkeeping
    Process.unlink pid_key

    registry
  end

  defp do_remove(%Registry{} = registry, :active_ids, {id_key, pid_key} = _key)
  when is_binary(id_key) and is_pid(pid_key) do

    Logger.debug("About to remove id from active list")

    registry = 
      case Map.get(registry.active_ids, id_key) do
        nil -> 
          # Flag as error if we can't find pid in our system
          # something is weird
          raise HangmanError, "Can't remove a id that doesn't exist"
        ^pid_key -> 
          # Match against id value
          # First, remove pid from active_pids mapping
          active_ids = Map.delete(registry.active_ids, id_key)
          registry = Kernel.put_in(registry.active_ids, active_ids)
          registry
        _ ->
          # We have the pid but it has a different id_key! flag error
          raise HangmanError, "id found, but different pid. Strange!"
          
      end

    registry
  end



end
