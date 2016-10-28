defmodule Hangman.Pass.Cache.Writer do  
  @moduledoc """
  Module is responsible for synchronous chunk 
  `pass` writes into the `Pass.Cache` table. 

  Serves as a write operation specific process to isolate write 
  errors from Pass.Cache

  NOTE: Could be a source of bottleneck as all reduce workers
  are synchronously relying on this writer process.  As of current
  load, no bottleneck for time being
  """

  use GenServer
  alias Hangman.{Pass, Chunks}
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
  
  @spec put(Pass.key, Chunks.t) :: :ok
  def put({id, game_no, round_no} = pass_key, %Chunks{} = chunks)
  when (is_binary(id) or is_tuple(id)) 
  and is_number(game_no) and is_number(round_no) do
    GenServer.call(:pass_cache_writer, {:put, pass_key, chunks})
  end

  @callback handle_call({atom, Pass.key, Chunks.t}, tuple, tuple) :: tuple
  def handle_call({:put, pass_key, %Chunks{} = chunks}, _from, state) do

    if :ets.info(@ets_table_name) == :undefined do
      raise HangmanError, "table not loaded yet"
    end
    
    :ets.insert(@ets_table_name, {pass_key, chunks})

    _ = Logger.debug "inserted chunks into pass key " <> 
      "#{inspect [self, pass_key, chunks]}"

    {:reply, :ok, state}
  end

end
