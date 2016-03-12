defmodule Pass.Writer.Worker do
  use GenServer

  @moduledoc """
  Module is a `GenServer` that implements writer worker functionality.
  Specifically, Pass.Writer.Worker is a `write-operation` specific module that 
  performs `async` writes into `Pass.Cache` `ETS` table.

  If the `Pass.Writer.Worker.write/3` operation fails for whatever reason, 
  it doesn't bring down the table-owning `Pass.Cache` process and interrupt
  cache reads.  Hence the separation. The primary module method is 
  `Pass.Writer.Worker.write/3`
  """
  
  require Logger

  @name __MODULE__
  @ets_table_name :engine_pass_table

  @docp """
  GenServer start_link wrapper function
  """
  
  #@spec start_link(pos_integer) :: GenServer.on_start
  def start_link(worker_id) do
    Logger.debug "Starting Pass Writer Worker #{worker_id}"

    args = {}
    options = [name: via_tuple(worker_id)]
    GenServer.start_link(@name, args, options)
  end

  @doc """
  Issues request to stop GenServer `worker`
  """
  
  @spec stop(pid) :: {}
  def stop(pid) do
    GenServer.call pid, :stop
  end

  @doc """
  Write is an `asynchronous` call.
  Inserts `chunks` into `ETS` pass table
  """

  @spec write(pos_integer, Pass.key, Chunks.t) :: :ok
  def write(worker_id, {id, game_no, round_no} = pass_key, 
            %Chunks{} = chunks)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do

    Logger.debug "pass writer worker #{worker_id}, write arg list " <> 
      "#{inspect [worker_id, pass_key, chunks]}"
    
    GenServer.cast(via_tuple(worker_id), {:write, pass_key, chunks})
  end
  
  # Used to register / lookup process in process registry via gproc
  
  @spec via_tuple(String.t) :: tuple
  defp via_tuple(worker_id) do
    {:via, :gproc, {:n, :l, {:pass_writer_worker, worker_id}}}
  end
  
  @docp """
  GenServer callback to initalize server process
  """
  
  #@callback init({}) :: {}
  def init({}) do
    {:ok, {}}
  end
  
  @docp """
  Writes pass data chunk, uses pass_key for ets insertion
  """
  
  #@callback handle_cast(:atom, Pass.key, Chunks.t, {}) :: tuple
  def handle_cast({:write, {id, game_no, round_no} = _pass_key,
                   %Chunks{} = chunks}, {}) do
    
    if :ets.info(@ets_table_name) == :undefined do
      raise HangmanError, "table not loaded yet"
    end
    
    next_pass_key = {id, game_no, round_no + 1}
    :ets.insert(@ets_table_name, {next_pass_key, chunks})
    
    {:noreply, {}}
  end
  
  @docp """
  Issues request to stop GenServer
  """
  
  #@callback handle_call(:atom, tuple, {}) :: tuple
  def handle_call(:stop, _from, {}) do
    { :stop, :normal, :ok, {}}
  end 
  
  @docp """
  Terminates the pass writer worker `server`
  No special cleanup
  """
  
  #@callback terminate(term, term) :: :ok
  def terminate(_reason, _state) do
    :ok
  end
end
