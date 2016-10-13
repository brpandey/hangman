defmodule Hangman.Flow do


  @moduledoc """
  Module distributes the game requests to the flow shard handler and 
  then collects the resultant game information 
  and combines it in the proper order.

  Game play is setup to be parallel and concurrent to use
  all the machines CPU cores.
  """

  alias Experimental.Flow
  alias Hangman.{Player, Flow.Shard}

  require Logger

  @flow_shard_size 10   # 1 flow shard contains 10 secrets


  @doc """
  Entry point for map-reduce "flow" processing and collation.

  Setups up flow engine.  For each game argument, sets up 
  the game state and then plays the game shards

  In terms of map-reduce frameworks, the collection vector
  contains the game argument tokens

  These game tokens are mapped to the Handler setup and play
  functions, which setup game play and carry it out.

  Finally, the results of play are reduced and store into a map.
  Whose entries are handed off back to the caller module
  """

  @spec run(Player.id, [String.t]) :: list | String.t
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
    
    result = Flow.from_enumerable(game_args, max_demand: 2)
    |> Flow.map(fn {shard_key, shard_value} ->
      {shard_key, shard_value} 
      |> Shard.Handler.setup 
      |> Shard.Handler.play
    end)
    |> Flow.partition
    |> Flow.reduce(fn -> %{} end, fn {key, history}, acc ->
      collate({key, history}, acc)
    end)
    |> Enum.into([])

    # Change from list to map
    result = result |> Enum.reduce(%{}, fn {k,v}, acc -> 
      Map.update(acc, k, v, &(&1 <> v))
    end)
    
    # Based on the secrets count either return single game history or score results
    case Enum.count(secrets) do
      0 -> raise "No secrets provided"
      # result of first shard, which is game history for 1 game, key is e.g. {"typhoon", 1}
      1 -> Map.get(result, {name, 1})
      # for multiple secrets return scores summary for unsharded key e.g. "typhoon"
      _ -> Map.get(result, name) |> summarize

    end

  end


  @docp """
  Collects game result information and stores into shard key
  Combines game summaries and stores into name key

  Each shard_key e.g. {"robin", 7} represents the 
  seventh shard of the "robin" games, and is the result of the 10 games played
  """

  @spec collate({Player.id, list(String.t)}, map) :: map
  defp collate({key, snapshot}, acc) do
      
    # destructure shard key
    {name, _shard_value} = key
    
    [_, scores] =  snapshot |> List.last |> String.split("Scores: ")
    
    # Store individual game snapshots into shard_key and
    # Store score results into name key (e.g. non-sharded)
    
    acc = acc 
    |> Map.put(key, snapshot) 
    |> Map.update(name, scores, &(&1 <> scores))
    
    acc
  end

  @docp """
  Prepend avg score and num game info to scores text by computing the average score
  """

  @spec summarize(String.t) :: String.t
  def summarize(scores) do

    # Convert a string such as:
    # " (JOLLITY: 25) (PEMICANS: 7) (PALPITATION: 5) (UNSILENT: 6) (SUPERPROFITS: 4) (GERUNDIVE: 6) (PILEATE: 7) (OVERAWES: 8) (TUSSORS: 6) (ENDARTERECTOMY: 1) (NONADDITIVE: 3) (WAIVE: 25) (MACHINEABILITY: 4) (COURANTO: 6) (NONOCCUPATIONAL: 4) (SLATED: 7) (REMARKET: 6) (BRACTLET: 6) (SPECTROMETRIC: 2) (OXIDOREDUCTASES: 2)"

    l = scores |> String.split([" (", ") (" , ")"], trim: true)

    # After the String.split we have a list like so:

    #["JOLLITY: 25", "PEMICANS: 7", "PALPITATION: 5", "UNSILENT: 6",
    # "SUPERPROFITS: 4", "GERUNDIVE: 6", "PILEATE: 7", "OVERAWES: 8", "TUSSORS: 6",
    # "ENDARTERECTOMY: 1", "NONADDITIVE: 3", "WAIVE: 25", "MACHINEABILITY: 4",
    # "COURANTO: 6", "NONOCCUPATIONAL: 4", "SLATED: 7", "REMARKET: 6", "BRACTLET: 6", 
    # "SPECTROMETRIC: 2", "OXIDOREDUCTASES: 2"]
    
    games = l |> Enum.count

    total_score = l |> Enum.reduce(0, fn x, acc -> 
      [_a, b] = String.split(x, ": ")   
      score = String.to_integer(b)
      acc + score
    end)
    
    avg = total_score / games
    
    "Game Over! Average Score: #{avg}, # Games: #{games}, Scores: #{scores}"
  end

end
