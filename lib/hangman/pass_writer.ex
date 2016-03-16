defmodule Pass.Writer do
  
  @moduledoc """
  Module is responsible for words `pass` writes into the `Pass.Cache` table. 
  The write `load` is handled through the `Pass.Writer.Pool`. It distributes
  `write/2` request based on the `pass` key id attribute to `workers`.

  The writer pool supervisor supervises the workers, which are each 
  responsible for the write operations. The primary `writer` worker 
  method is `Pass.Writer.Worker.write/3`
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
  Write is an `asynchronous` call, there is no need to wait around for 
  the response. Based on the key `id`, selects the writer `worker` to
  hand the request off to.
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
