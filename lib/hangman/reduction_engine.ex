defmodule Hangman.Reduction.Engine do

  @moduledoc """
  Module implements words reduction engine.

  Reduce load is handled through pool.
  Distributes reduce requests based on pass key id attribute (name)
  Pool size reduction workers are started up as part of reducer pool
  Pool supervisor supervises reduction workers
  """

  alias Hangman.{Reduction.Engine, Types.Reduction.Pass}

  @pool_size 10

  @doc """
  Supervisor start_link wrapper function
  Starts pool supervisor
  """

  @spec start_link :: Supervisor.on_start
  def start_link() do
    Engine.Pool.Supervisor.start_link(@pool_size)
  end

  @doc """
  Calls synchronous worker process function reduce and store
  Based on key id, selects reduction worker to hand off request to
  """
  
  @spec reduce(tuple, term, Regex.t) :: Pass.t
  def reduce(pass_key, regex_key, %MapSet{} = exclusion_set) do
    {id_key, _, _} = pass_key

    id_key 
    |> choose_worker 
    |> Engine.Worker.reduce_and_store(pass_key, regex_key, exclusion_set)
  end

  # Given key, returns erlang portable hash, mod size of the pool
  
  @spec choose_worker(String.t) :: pos_integer
  defp choose_worker(key) when is_binary(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

end
