defmodule Hangman.Reduction.Engine.Pool.Supervisor do
  use Supervisor

  @moduledoc """
  Module is a Supervisor that supervises a pool of 
  word reduction workers
  """

  @name __MODULE__

  @doc """
  Supervisor start_link wrapper function
  Accepts pool size as arg
  """
  
  @spec start_link(pos_integer) :: Supervisor.on_start
  def start_link(pool_size) do
    Supervisor.start_link(@name, {pool_size})
  end

  @doc """
  For each worker in pool, creates a reducer worker process
  specification to be supervised once supervisor started
  """

  @callback init(tuple) :: {:ok, tuple}
  def init({pool_size}) do
    processes = for worker_id <- 1..pool_size do
      # Create worker spec for each value
      worker(
        Hangman.Reduction.Engine.Worker, [worker_id],
        id: {:reduction_engine_worker, worker_id}
      )
    end

    # Supervise each of above defined workers
    supervise(processes, strategy: :one_for_one)
  end

end
