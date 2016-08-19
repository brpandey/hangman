defmodule Hangman.Pass.Cache do
  use GenServer

  @moduledoc """
  Module provides cache access to the game words pass.
  Given a player, a game and round number, `Pass.Cache` maintains a words pass 
  `cache` of current word passes.  The words are represented by `Chunks`.  

  Implements a `get/1` and `put/2` routine to retrieve and store these word 
  pass `Chunks`.

  Given a new `Hangman` game, initially the words pass is the size of all words
  in the dictionary of secret length k.  As each round proceeds, this is reduced by the 
  `Hangman` pattern sequence.  It is these remaining possible word set instances
  that are stored in the cache.

  After each player has made their `Hangman` round guess, the resultant reduced
  words `pass` data is stored into the `Pass.Cache` for access on the 
  subsequent round.  The expired `pass` data from stale rounds is subsequently 
  removed from the `cache`.
  """

  require Logger
  
  alias Hangman.{Pass, Chunks}
  
  @name __MODULE__
  @ets_table_name :hangman_pass_cache


  # External API

  @docp """
  GenServer start link wrapper function
  """
  
  #@spec start_link :: Supervisor.on_start
  def start_link() do
    Logger.info "Starting Hangman Pass Cache GenServer"
    args = {}
    options = [name: :hangman_pass_cache] # same name for table as process
    GenServer.start_link(@name, args, options)
  end

  @doc """
  Routine to stop server normally
  """

  @spec stop(pid) :: {}
  def stop(pid) do
    GenServer.call pid, :stop
  end

  @docp """
  GenServer callback to initialize server process
  """

  #@callback init(term) :: {}
  def init(_) do
    setup()
    {:ok, {}}
  end

  @docp """
  GenServer callback to stop server
  """
  
  #@callback handle_call(:atom, {}, {}) :: {}
  def handle_call(:stop, _from, {}) do
    { :stop, :normal, :ok, {}}
  end 

  @docp """
  GenServer callback to cleanup server state
  """

  #@callback terminate(reason :: term, {}) :: term | no_return
  def terminate(_reason, _state) do
    :ok
  end

  # Loads ets table type set
  
  @spec setup :: :atom
  defp setup() do
    :ets.new(@ets_table_name, [:set, :named_table, :public])
  end


  @docp """
  Get routine retrieves `pass` chunks cache data given pass key
  """

  @spec get(Pass.key) :: Chunks.t | no_return
  def get({id, game_no, round_no} = pass_key)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do

    Logger.debug("pass cache get: pass_key is #{inspect pass_key}")

    case do_get(:chunks, pass_key) do
      
      nil ->
        Logger.debug("Unable to retrieve chunks from rounds_pass_cache," 
                     <> " given pass_key #{inspect pass_key}")
        
        snapshot_info = :ets.i(@ets_table_name)
        Logger.debug("Table snapshot: #{inspect snapshot_info}")
        
        raise HangmanError, "chunks not found for key: #{inspect pass_key}"

      data -> data
    end
  end


  @spec do_get(atom, Pass.key) :: Chunks.t | nil
  defp do_get(:chunks, {_id, _game_no, _round_no} = pass_key) do
    
    # Using match instead of lookup, to keep processing on the ets side
    case :ets.match_object(@ets_table_name, {pass_key, :_}) do
      [] -> nil
      [{^pass_key, data}] ->

        %Chunks{} = data # quick assert

        # delete this current pass in the table, 
        # since we only keep 1 pass for each user
        :ets.match_delete(@ets_table_name, {pass_key, :_})
    
        # return chunks :)
        data
    end

  end
  

  @spec put(Pass.key, Chunks.t) :: :ok | no_return
  def put({_id, _game_no, _round_no} = pass_key, %Chunks{} = data) do
    :ok = Pass.Cache.Writer.put(pass_key, data)
  end

end
