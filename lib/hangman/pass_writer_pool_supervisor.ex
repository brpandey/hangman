defmodule Hangman.Pass.Writer.Pool.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link(pool_size) do
    Supervisor.start_link(@name, {pool_size})
  end

  def init({pool_size}) do
    processes = for worker_id <- 1..pool_size do
      # Create worker spec for each value
      worker(
        Hangman.Pass.Writer.Worker, [worker_id],
        id: {:pass_writer_worker, worker_id}
      )
    end

    supervise(processes, strategy: :one_for_one)
  end

end
