defmodule Hangman.Pass.Cache do
  use GenServer

  @moduledoc """
  Module provides cache access to the game words pass.
  Given a player, a game and round number, `Pass.Cache` maintains a words pass `cache`
  of current word passes.

  Given a new `Hangman` game, initially the words pass is the size of all words
  in the dictionary of secret length k.  As each round proceeds, this is reduced by the 
  `Hangman` pattern sequence.  It is these remaining possible word set instances
  that are stored in the cache.

  After each player has made their `Hangman` round guess, the resultant reduced
  words `pass` data is stored into the `Pass.Cache` for access on the 
  subsequent round.  The expired `pass` data from stale rounds is subsequently 
  removed from the `cache`.

  `Pass.Cache` performs `unserialized` reads and uses type `key` for 
  cache  `get/2` and `get/3`. 
  """

  require Logger
  
  alias Hangman.Dictionary.Cache, as: DCache
  alias Hangman.{Pass, Reduction, Chunks, Counter}
  
  @name __MODULE__
  @ets_table_name :hangman_pass_cache

  @type key :: :chunks | {:pass, :game_start} | {:pass, :game_keep_guessing}

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

  @doc """
  Get routine retrieves the `pass` size, tally, possible words, 
  and other data given these cache `keys`. Relies on either the Dictionary
  Cache or the Reduction Engine to compute new pass data

    * `{:pass, :game_start}` - this is the initial game start `pass`, so we 
    request the data from the `Dictionary.Cache`.  The data is stored into 
    the `Pass.Cache` via `Pass.Cache.Writer.write/2`. Returns `pass` data type.

    * `{:pass, :game_keep_guessing}` - retrieves the pass data from the last 
    player round and relies on `Reduction.Engine.reduce/3` to reduce the possible
    `Hangman` words set with `reduce_key`.  When the reduction is finished, we 
    write the data back to the `Pass.Cache` and return the new `pass` data.
  """


  @spec get(cache_key :: Pass.Cache.key, pass_key :: Pass.key, 
            reduce_key :: Reduction.key) :: {Pass.key, Pass.t} | no_return
  def get({:pass, :game_start} = _cache_key, 
          {id, game_no, round_no} = pass_key, reduce_key)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do

    # Asserts
    {:ok, true} = Keyword.fetch(reduce_key, :game_start)
    {:ok, length_key}  = Keyword.fetch(reduce_key, :secret_length)
    
    # Since this is the first pass, grab the words and tally from
    # the Dictionary Cache

    # Subsequent round lookups will be from the pass table

    chunks = %Chunks{} = DCache.lookup(:chunks, length_key)
    tally = %Counter{} = DCache.lookup(:tally, length_key)

    pass_size = Chunks.count(chunks)
    pass_info = %Pass{ size: pass_size, tally: tally, last_word: ""}

    # Store pass info into ets table for round 2 (next pass)
    # Allow writer engine to execute (and distribute) as necessary

    next_pass_key = Pass.increment_key(pass_key)
    Pass.Cache.Writer.put(next_pass_key, chunks)
  
    {pass_key, pass_info}
  end


  def get({:pass, :game_keep_guessing} = _cache_key, 
          {id, game_no, round_no} = pass_key, reduce_key)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do
    
    {:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
    {:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)
  
    # Send pass and reduce information off to Engine server
    # to execute (and distribute) as appropriate
    # operation subsequently writes back to pass_cache
    pass_info = Reduction.Engine.reduce(pass_key, regex_key, exclusion_set)

    {pass_key, pass_info}
  end

  @docp """
  Get routine retrieves `pass` chunks cache data given pass key
  """

  @spec cached_get(atom, Pass.key) :: Chunks.t | no_return
  def get(:chunks, {id, game_no, round_no} = pass_key)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do

    Logger.debug("pass cache get: pass_key is #{inspect pass_key}")

    case cached_get(:chunks, pass_key) do
      
      nil ->
        Logger.debug("Unable to retrieve chunks from rounds_pass_cache," 
                     <> " given pass_key #{inspect pass_key}")
        
        snapshot_info = :ets.i(@ets_table_name)
        Logger.debug("Table snapshot: #{inspect snapshot_info}")
        
        raise HangmanError, "chunks not found for key: #{inspect pass_key}"

      data -> data
    end
  end


  @spec cached_get(atom, Pass.key) :: Chunks.t | nil
  def cached_get(:chunks, {_id, _game_no, _round_no} = pass_key) do
    
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
  

  @spec put(atom, Pass.key, Chunks.t) :: :ok | no_return
  def put(:chunks,  {_id, _game_no, _round_no} = pass_key, %Chunks{} = data) do
    :ok = Pass.Cache.Writer.put(pass_key, data)
  end

end
