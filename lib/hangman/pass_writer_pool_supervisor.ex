defmodule Hangman.Pass.Writer.Pool.Supervisor do
  use Supervisor

  @moduledoc """
  Module is a Supervisor that supervises a pool
  of Pass Writer Workers
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
  For each worker in pool, creates a Writer Worker process
  specification to be supervised once supervisor started
  """

  @callback init(tuple) :: {:ok, tuple}
  def init({pool_size}) do

    # Use list comp to generate worker specification
    # for each item in pool size
    processes = for worker_id <- 1..pool_size do
      # Create worker spec for each value
      worker(
        Hangman.Pass.Writer.Worker, [worker_id],
        id: {:pass_writer_worker, worker_id}
      )
    end

    # Supervise each of above defined workers
    supervise(processes, strategy: :one_for_one)
  end

end
