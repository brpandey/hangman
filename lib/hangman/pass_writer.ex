defmodule Hangman.Pass.Writer do
  @pool_size 10

  alias Hangman.{Word.Chunks, Pass.Writer}

  def start_link() do
    Writer.Pool.Supervisor.start_link(@pool_size)
  end

  # write  is an asynchronous call, no need to wait around for response
  def write({id, game_no, round_no} = pass_key, %Chunks{} = chunks)
  when is_binary(id) and is_number(game_no) and is_number(round_no) do
    {id_key, _, _} = pass_key

    id_key 
    |> choose_worker
    |> Writer.Worker.write(pass_key, chunks)
  end

  defp choose_worker(key) when is_binary(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

end
