defmodule Hangman.Reduction.Engine do
  @pool_size 10

  alias Hangman.{Reduction.Engine}

  def start_link() do
    Engine.Pool.Supervisor.start_link(@pool_size)
  end

  def reduce(pass_key, regex_key, %MapSet{} = exclusion_set) do
    {id_key, _, _} = pass_key

    id_key 
    |> choose_worker 
    |> Engine.Worker.reduce_and_store(pass_key, regex_key, exclusion_set)
  end

  defp choose_worker(key) when is_binary(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

end
