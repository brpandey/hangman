defmodule Pass.Writer do
  
  @moduledoc """
  Module implements words pass write functionality into the Pass.Cache `ETS` table.

  Write load is handled through `Pass.Writer.Pool`.
  Pool distributes write request based on pass key id attribute (name).
  Pool size writer workers are started up as part of writer pool.
  Pool supervisor supervises writer workers, which are each responsible for
  the write operations.

  Primary method is `Pass.Writer.Worker.write/3`
  """
    
  @pool_size 10
  
  @doc """
  Supervisor start_link wrapper function
  Starts pool supervisor
  """
  
  @spec start_link :: Supervisor.on_start
  def start_link do
    Pass.Writer.Pool.start_link(@pool_size)
  end
  
  
  @doc """
  Write is an asynchronous call, no need to wait around for response
  Based on key id, selects writer worker to hand off request to
  """
  
  @spec write(Pass.key, Chunks.t) :: :ok
  def write({id, game_no, round_no} = pass_key, %Chunks{} = chunks)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do
    {id_key, _, _} = pass_key
    
    id_key 
    |> choose_worker
    |> Pass.Writer.Worker.write(pass_key, chunks)
  end
  
  
  # Given key, returns erlang portable hash, mod size of the pool
  
  @spec choose_worker(String.t) :: pos_integer
  defp choose_worker(key) when is_binary(key) do
    :erlang.phash2(key, @pool_size) + 1
  end
  
end
