defmodule Hangman.Pass.Cache.Writer do  
  @moduledoc """
  Module is responsible for synchronous words 
  `pass` writes into the `Pass.Cache` table. 

  Serves as a write operation specific process to isolate write 
  errors from Pass.Cache

  NOTE: Could be a source of bottleneck as all reduce workers
  are synchronously relying on this writer process.  As of current
  load, no bottleneck for time being
  """

  use GenServer
  alias Hangman.{Pass, Words}
  require Logger
    
  @ets_table_name :hangman_pass_cache

  @doc """
  Starts GenServer
  """

  #@spec start_link :: Supervisor.on_start
  def start_link() do
    _ = Logger.debug "Starting Hangman Pass Cache Writer"
    args = {}
    options = [name: :pass_cache_writer]
    GenServer.start_link(__MODULE__, args, options)
  end

  @doc """
  Routine to stop server normally
  """

  @spec stop() :: {}
  def stop() do
    GenServer.call :pass_cache_writer, :stop
  end
  
  @docp """
  GenServer callback to initialize server process
  """
  
  #@callback init(term) :: {}
  def init(_) do
    {:ok, {}}
  end
  
  @doc """ 
  Write is synchronous
  """
  
  @spec put(Pass.key, Words.t) :: :ok
  def put({id, game_no, round_no} = pass_key, %Words{} = words)
  when (is_binary(id) or is_tuple(id)) 
  and is_number(game_no) and is_number(round_no) do
    GenServer.call(:pass_cache_writer, {:put, pass_key, words})
  end

  @callback handle_call({atom, Pass.key, Words.t}, tuple, tuple) :: tuple
  def handle_call({:put, pass_key, %Words{} = words}, _from, state) do

    if :ets.info(@ets_table_name) == :undefined do
      raise HangmanError, "table not loaded yet"
    end
    
    :ets.insert(@ets_table_name, {pass_key, words})

    _ = Logger.debug "inserted words into pass key " <> 
      "#{inspect [self, pass_key, words]}"

    {:reply, :ok, state}
  end

  @docp """
  GenServer callback to stop server
  """
  
  #@callback handle_call(:atom, {}, {}) :: {}
  def handle_call(:stop, _from, {}) do
    { :stop, :normal, :ok, {}}
  end 

end
