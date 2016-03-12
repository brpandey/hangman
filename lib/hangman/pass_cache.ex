defmodule Pass.Cache do
  use GenServer

  @moduledoc """
  Given a player, a game and round number, `Pass.Cache` maintains a words pass `cache`.

  Internally the module implements a `GenServer` which uses `ETS`.

  After each player has made their `Hangman` round guess, the resultant reduced
  words `pass` data is stored into the `Pass.Cache` for access on the 
  subsequent round.  The expired `pass` data from stale rounds is subsequently 
  removed from the `cache`.

  `Pass.Cache` performs `unserialized` reads and uses type `key` for cache  `get/2` and `get/3`. 
  """

  require Logger
  
  alias Dictionary.Cache, as: DCache
  
  @name __MODULE__
  @ets_table_name :engine_pass_table

  @type key :: :chunks | {:pass, :game_start} | {:pass, :game_keep_guessing}

  # External API

  @docp """
  GenServer start link wrapper function
  """
  
  #@spec start_link :: Supervisor.on_start
  def start_link() do
    Logger.info "Starting Hangman Pass Cache GenServer"
    args = {}
    options = []
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
  and other data given these cache `keys`.

    * `{:pass, :game_start}` - this is the initial game start `pass`, so we 
    request the data from the `Dictionary.Cache`.  The data is stored into 
    the `Pass.Cache` via `Pass.Writer.write/2`. Returns `pass` data type.

    * `{:pass, :game_keep_guessing}` - retrieves the pass data from the last 
    player round and relies on `Reduction.Engine.reduce/3` to reduce the possible
    `Hangman` words set with `reduce_key`.  When the reduction is finished, we 
    write the data back to the `Pass.Cache` and return the new `pass` data.

  These get requests are not `serialized` through the server
  process since we are doing `reads`
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
    Pass.Writer.write(pass_key, chunks)
  
    {pass_key, pass_info}
  end


  def get({:pass, :game_keep_guessing} = _cache_key, 
          {id, game_no, round_no} = pass_key, reduce_key)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do
    
    {:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
    {:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)
  
    # Send pass and reduce information off to Engine server
    # to execute (and distribute) as appropriate
    pass_info = Reduction.Engine.reduce(pass_key, regex_key, exclusion_set)

    {pass_key, pass_info}
  end

  @doc """
  Get routine retrieves `pass` chunks cache data

  We can obtain `chunks` data, for cache `keys` with the `:chunks` atom
    * `:chunks` - retrieves chunks data for a given pass key

  These get requests are not `serialized` through the 
  server process since we are doing `reads`
  """
  
  @spec get(Pass.Cache.key, Pass.key) :: Chunks.t | no_return
  def get(:chunks = _cache_key, {id, game_no, round_no} = pass_key)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do
    
    # Using match instead of lookup, to keep processing on the ets side
    case :ets.match_object(@ets_table_name, {pass_key, :_}) do
      [] -> 
        raise HangmanError, 
        "counter not found for key: #{inspect pass_key}"

      [{_key, chunks}] ->
        %Chunks{} = chunks # quick assert

        # delete this current pass in the table, 
        # since we only keep 1 pass for each user
        :ets.match_delete(@ets_table_name, {pass_key, :_})
    
        # return chunks :)
        chunks
    end

  end
end
