defmodule Hangman.Web.Collator do


  @moduledoc """
  Module distributes web requests to
  player workers and then collects information 
  and combines it in the proper order.
  """

  alias Experimental.Flow
  alias Hangman.{Player, Web}

  require Logger

  @shard_size 2   # 1 shard contains 2 secrets

  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(Player.id, Player.kind, [String.t], boolean, boolean) :: :ok

  def run(name, :robot, secrets, false, false)
  when is_list(secrets) and is_binary(hd(secrets)) do
    {name, :robot, secrets, false, false} |> flow
  end

  @docp """
  Function setup loads the `player` specific `game` components.
  Setups the `game` server and per player `event` server.
  """
  
  @spec flow(tuple()) :: tuple
  defp flow({name, :robot, secrets, false, false}) when 
  is_binary(name) and is_list(secrets) and is_binary(hd(secrets)) do

    # e.g secrets
    # ["radical", "rabbit", "mushroom", "petunia"]    
    sharded_keys = Stream.cycle([name]) |> Stream.with_index(1)

    # currently each shard has 2 secrets
    sharded_secrets = secrets |> Stream.chunk(@shard_size, @shard_size, []) 
    
    # zips the two streams into a format like the following:
    # [{{"fred", 1}, ["radical", "rabbit"]}, {{"fred", 2}, ["mushroom", "petunia"]}]

    # A single shard key is {"fred", 1}, and shard value is ["radical", "rabbit"]

    game_args = Stream.zip(sharded_keys, sharded_secrets)
    
    result = game_args
    |> Flow.from_enumerable()
    |> Flow.map(fn {shard_key, shard_value} ->
      {shard_key, shard_value} 
      |> Web.Handler.setup 
      |> Web.Handler.play
    end)
#    |> Flow.partition()
    |> Flow.reduce(fn -> %{} end, fn {key, history}, acc ->
      collate({key, history}, acc)
    end)
    |> Enum.into(%{})

    case Enum.count(secrets) do
      0 -> raise "No secrets provided"
      # result of first shard, which is game history for 1 game
      1 -> Map.get(result, {name, 1})
      # for multiple secrets return scores summary
      _ -> Map.get(result, name) 
    end

  end

  defp collate({game_key, game_history}, acc) do
      
    # destructure shard key
    {name, _} = game_key
    
    summary = List.last(game_history)
    [_, scores] = String.split(summary, "Scores: ")
    
    IO.puts "scores are #{inspect scores}"
    
    # Store individual game summaries into shard_key and
    # Store score results into name key (e.g. non-sharded)
    
    acc = acc 
    |> Map.put(game_key, game_history) 
    |> Map.update(name, scores, &(&1 <> scores))
    
    IO.puts "scores acc is #{inspect Map.get(acc, name)}"
    
    acc

  end

end
