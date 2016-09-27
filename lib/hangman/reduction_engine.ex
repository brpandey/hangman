defmodule Hangman.Reduction.Engine do

  @moduledoc """
  Module provides access to the words reduction engine.  
  
  Reduces possible `Hangman` words set based on the provided reduce `key`.  Reduction 
  `load` is handled through `Reduction.Engine.Pool`.
  
  The `Reduction.Engine` distributes `reduce/3` requests based on 
  the pass key id attribute to `workers`. Engine workers are started up 
  as part of the reducer pool.

  The pool supervises the reduction `workers`.
  """

  alias Hangman.{Reduction.Engine, Pass}

  @pool_size 10

  @doc """
  Supervisor start link wrapper function
  Starts pool `Supervisor`
  """

  @spec start_link :: Supervisor.on_start
  def start_link() do
    Engine.Pool.start_link(@pool_size)
  end

  @doc """
  Distributes reduce request to appropriate `worker`.
  Calls synchronous `worker` process function `Reduction.Engine.Worker.reduce_and_store/4`.
  Hands off request based on key id.
  """
  
  @spec reduce(Pass.key, Regex.t, Enumerable.t) :: Pass.t
  def reduce(pass_key, regex_key, %MapSet{} = exclusion_set) do
    {id_key, _, _} = pass_key

    id_key 
    |> choose_worker 
    |> Engine.Worker.reduce_and_store(pass_key, regex_key, exclusion_set)
  end

  # Given key, returns erlang portable hash, mod size of the pool
  
  @spec choose_worker(String.t | tuple) :: pos_integer
  defp choose_worker(key) when is_binary(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

  defp choose_worker({shard_name, shard_number} = key) when is_tuple(key) do
    :erlang.phash2(shard_name <> "#{shard_number}", @pool_size) + 1
  end


end
