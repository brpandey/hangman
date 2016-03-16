defmodule Pass.Writer.Pool do
  use Supervisor

  @moduledoc """
  Module is a `Supervisor` that supervises a `pool`
  of pass writer workers.

  Write `load` is handled through `Pass.Writer.Pool`.
  Module `distributes` write requests in the form of `Pass.Writer.write/2`
  requests based on `pass` key `id` attribute.
  """

  @name __MODULE__

  @docp """
  Supervisor start_link wrapper function. Accepts pool size as arg
  """
  
  #@spec start_link(pos_integer) :: Supervisor.on_start
  def start_link(pool_size) do
    Supervisor.start_link(@name, pool_size)
  end

  @doc """
  For each `worker` in `pool`, creates a writer worker process
  `specification` to be supervised once `Supervisor` started
  """

  @callback init(pool_size :: pos_integer) :: {:ok, tuple}
  def init(pool_size) do

    # Use list comp to generate worker specification
    # for each item in pool size
    processes = for worker_id <- 1..pool_size do
      # Create worker spec for each value
      worker(
        Pass.Writer.Worker, [worker_id],
        id: {:pass_writer_worker, worker_id}
      )
    end

    # Supervise each of above defined workers
    supervise(processes, strategy: :one_for_one)
  end

end
