defmodule Hangman.Pass.Writer.Worker do
  use GenServer

  @moduledoc """
  Module is a GenServer that implements writer worker functionality.
  Specifically, performs async write into pass ets table
  """
  
  require Logger

  alias Hangman.{Word.Chunks}

  @name __MODULE__
  @ets_table_name :engine_pass_table

  @doc """
  GenServer start_link wrapper function
  """
  
  @spec start_link(pos_integer) :: GenServer.on_start
  def start_link(worker_id) do
    Logger.debug "Starting Pass Writer Worker #{worker_id}"

    args = {}
    options = [name: via_tuple(worker_id)]
    GenServer.start_link(@name, args, options)
  end

  @doc """
  Issues request to stop GenServer worker
  """
  
  @spec stop(pid) :: {}
	def stop(pid) do
		GenServer.call pid, :stop
	end

  @doc """
  Write is an asynchronous call.
  Insert chunks into ets pass table
  """

  @spec write(pos_integer, tuple, Chunks.t) :: :ok
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
  
  @doc """
  GenServer callback to initalize server process
  """
  
  @callback init({}) :: {}
  def init({}) do
    {:ok, {}}
  end
  
	@doc """
	Writes pass data chunk, uses pass_key for ets insertion
	"""
  
  @callback handle_cast(:atom, tuple, Chunks.t, {}) :: tuple
  def handle_cast({:write, {id, game_no, round_no} = _pass_key,
                   %Chunks{} = chunks}, {}) do
    
		if :ets.info(@ets_table_name) == :undefined do
      raise Hangman.Error, "table not loaded yet"
    end
    
		next_pass_key = {id, game_no, round_no + 1}
		:ets.insert(@ets_table_name, {next_pass_key, chunks})
    
    {:noreply, {}}
  end
  
  @doc """
  Issues request to stop GenServer
  """
  
  @callback handle_call(:atom, tuple, {}) :: tuple
	def handle_call(:stop, _from, {}) do
		{ :stop, :normal, :ok, {}}
	end 
  
	@doc """
	Terminates the pass writer worker server
	No special cleanup
	"""
  
  @callback terminate(term, term) :: :ok
	def terminate(_reason, _state) do
		:ok
	end
end
