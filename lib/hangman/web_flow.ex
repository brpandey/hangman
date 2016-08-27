defmodule Hangman.Web.Flow do


  @moduledoc """
  Module distributes the game requests to the
  player workers and then collects the resultant game information 
  and combines it in the proper order.
  """

  alias Experimental.Flow
  alias Hangman.{Player, Web.Shard}

  require Logger

  @flow_shard_size 10   # 1 flow shard contains 10 secrets


  @doc """
  Entry point for map-reduce "flow" processing and collation.

  Setups up flow engine.  For each game argument, sets up 
  the game state and then plays the game shards

  In terms of map-reduce frameworks, the collection vector
  contains the game argument tokens

  These game tokens are mapped to the Web.Handler setup and play
  functions, which setup game play and carry it out.

  Finally, the results of play are reduced and store into a map.
  Whose entries are handed off back to the Web module
  """

  @spec run(Player.id, [String.t]) :: :ok  
  def run(name, secrets) when
  is_binary(name) and is_list(secrets) and is_binary(hd(secrets)) do

    # e.g secrets
    # ["radical", "rabbit", "mushroom", "petunia"]    
    sharded_keys = Stream.cycle([name]) |> Stream.with_index(1)

    # each shard has @flow_shard_size secrets, 
    # add empty list at end so we don't miss leftovers
    sharded_secrets = secrets |> Stream.chunk(@flow_shard_size, @flow_shard_size, []) 
    
    # zips the two streams into a format like the following:
    # [{{"fred", 1}, ["radical", "rabbit"]}, {{"fred", 2}, ["mushroom", "petunia"]}]

    # A single shard key is {"fred", 1}, and shard value is ["radical", "rabbit"]

    game_args = Stream.zip(sharded_keys, sharded_secrets)
    
    result = game_args
    |> Flow.from_enumerable()
    |> Flow.map(fn {shard_key, shard_value} ->

      IO.puts("in flow map self: #{inspect self}")

      {shard_key, shard_value} 
      |> Shard.Handler.setup 
      |> Shard.Handler.play


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


  @docp """
  Collects game result information and stores into shard key
  Combines game summaries and stores into name key

  Each shard_key e.g. {"robin", 7} represents the 
  seventh shard of the "robin" games, and is the result of (# secrets/shard) games played
  """

  @spec collate(tuple, term) :: term
  defp collate({key, snapshot}, acc) do
      
    # destructure shard key
    {name, _shard_value} = key
    
    [_, scores] =  snapshot |> List.last |> String.split("Scores: ")
    
    #IO.puts "key: #{inspect key}, key scores #{inspect scores}"
    
    # Store individual game snapshots into shard_key and
    # Store score results into name key (e.g. non-sharded)
    
    acc = acc 
    |> Map.put(key, snapshot) 
    |> Map.update(name, scores, &(&1 <> scores))
    
    #IO.puts "key: #{inspect key}, scores acc: #{inspect Map.get(acc, name)}"
  
    acc

  end

end
