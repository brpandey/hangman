defmodule Hangman.Pass.Writer.Worker do
  use GenServer
  
  require Logger

  alias Hangman.{Word.Chunks}

  @name __MODULE__
  @ets_table_name :engine_pass_table

  def start_link(worker_id) do
    Logger.debug "Starting Pass Writer Worker #{worker_id}"

    args = {}
    options = [name: via_tuple(worker_id)]
    GenServer.start_link(@name, args, options)
  end

	def stop(pid) do
		GenServer.call pid, :stop
	end


  # write  is an asynchronous call, no need to wait around for response
  def write(worker_id, {id, game_no, round_no} = pass_key, 
            %Chunks{} = chunks)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do

    Logger.debug "pass writer worker, write arg list " <> 
      "#{inspect [worker_id, pass_key, chunks]}"

    GenServer.cast(via_tuple(worker_id), {:write, pass_key, chunks})
  end

  defp via_tuple(worker_id) do
    {:via, :gproc, {:n, :l, {:pass_writer_worker, worker_id}}}
  end

  def init({}) do
    {:ok, {}}
  end
  
  def handle_cast({:write, {id, game_no, round_no} = _pass_key,
                   %Chunks{} = chunks}, {}) do

		if :ets.info(@ets_table_name) == :undefined do
      raise Hangman.Error, "table not loaded yet"
    end

		next_pass_key = {id, game_no, round_no + 1}
		:ets.insert(@ets_table_name, {next_pass_key, chunks})

    {:noreply, {}}
  end

	def handle_call(:stop, _from, {}) do
		{ :stop, :normal, :ok, {}}
	end 

	def terminate(_reason, _state) do
		:ok
	end
end
