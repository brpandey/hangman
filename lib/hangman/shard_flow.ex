defmodule Hangman.Shard.Flow do
  @moduledoc """
  Module splits the game args into shards
  which is distributed to shard handlers.  The resultant 
  game information is collected and combined in the proper order.

  Game play is setup to be parallel and concurrent to use
  all the machines CPU cores.

  A single shard key resembles the format: {name, shard num} or {"fred", 1}, 
  and the shard value is a list of secrets or ["radical", "rabbit"]
  """

  alias Experimental.Flow
  alias Hangman.{Player, Shard.Handler}
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
    
    result = 
      game_args
      |> Flow.from_enumerable(max_demand: 2)
      |> Flow.map(fn {skey, svalue} ->
           {skey, svalue} |> Handler.setup |> Handler.play
         end)
      |> Flow.partition
      |> Flow.reduce(fn -> %{} end, fn {key, history}, acc ->
           collate({key, history}, acc)
         end)
      |> Enum.into([])


    # Change from list to map
    result = 
      Enum.reduce(result, %{}, fn {k,v}, acc -> 
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
    
    acc 
    |> Map.put(key, snapshot) 
    |> Map.update(name, scores, &(&1 <> scores))

  end

  @docp """
  Prepend avg score and num game info to scores text by computing the average score
  """

  @spec summarize(String.t) :: String.t
  def summarize(scores) do

    # Convert a string to a form where we can easily extract score information and sort it:

    # (SUSPENSER: 2) (POLYMER: 6) (SHREWING: 8) (POSTNEONATAL: 3) (WEIGHTLESS: 5)
    # (IMMANENCES: 4) (FAVORABLY: 7) (UNGOVERNABLE: 4) (WORSEN: 9) (BICONVEXITY: 3)
    # (HOODIE: 8) (FLOPPIER: 10) (SWITCHING: 9) (WORSHIPING: 8) (DISOBEDIENCES: 4)
    # (MERCHANTED: 4) (MOTIVATE: 6) (SUNSCALD: 6) (CANONISING: 5) (BENZOLES: 7)
    # (PTYALINS: 7) (THERAPEUTIC: 2) (PEPLUMS: 25) (LANIARDS: 9) (RAINS: 7)
    # (GOBIOID: 4) (INVALIDITY: 5) (SUBLIMATE: 7) (FATHERLIKE: 4) (COOMBS: 8)
    # (BUFFETERS: 8) (JESUITS: 7) (COEDUCATIONS: 3) (MICROCLIMATIC: 3) 
    # (ALARMING: 6) (STROPHE: 5) (STATELIEST: 4) (UNDERNOURISHED: 4) (LARVAL: 6)
    # (BUSHFIRE: 6) (TRUSTED: 5) (GELEE: 3) (UNHUSK: 25) (VERIFY: 7) (STABILIZING: 6)
    # (WHOEVER: 4) (TASTEMAKERS: 4) (GLARIER: 7) (COSTUMER: 8) (DEPENDABLENESS: 3)"


    list = scores |> String.split([" (", ") (" , ")"], trim: true) |> Enum.sort

    # After the String.split we have a sorted list instead of a string, like so:

    # ["ALARMING: 6", "BENZOLES: 7", "BICONVEXITY: 3", "BUFFETERS: 8", 
    # "BUSHFIRE: 6", "CANONISING: 5", "COEDUCATIONS: 3", "COOMBS: 8", 
    # "COSTUMER: 8", "DEPENDABLENESS: 3", "DISOBEDIENCES: 4", "FATHERLIKE: 4", 
    # "FAVORABLY: 7", "FLOPPIER: 10", "GELEE: 3", "GLARIER: 7", "GOBIOID: 4", 
    # "HOODIE: 8", "IMMANENCES: 4", "INVALIDITY: 5", "JESUITS: 7", "LANIARDS: 9", 
    # "LARVAL: 6", "MERCHANTED: 4", "MICROCLIMATIC: 3", "MOTIVATE: 6", 
    # "PEPLUMS: 25", "POLYMER: 6", "POSTNEONATAL: 3", "PTYALINS: 7", "RAINS: 7", 
    # "SHREWING: 8", "STABILIZING: 6", "STATELIEST: 4", "STROPHE: 5", 
    # "SUBLIMATE: 7", "SUNSCALD: 6", "SUSPENSER: 2", "SWITCHING: 9", "TASTEMAKERS: 4", 
    # "THERAPEUTIC: 2", "TRUSTED: 5", "UNDERNOURISHED: 4", "UNGOVERNABLE: 4", 
    # "UNHUSK: 25", "VERIFY: 7", "WEIGHTLESS: 5", "WHOEVER: 4", "WORSEN: 9", "WORSHIPING: 8"]

    games = list |> Enum.count

    total_score = 
      Enum.reduce(list, 0, fn x, acc -> 
        [_a, b] = String.split(x, ": ")   
        score = String.to_integer(b)
        acc + score
      end)
    
    avg = total_score / games

    # Convert string back to scores list with paren format

    scores = 
      list 
      |> Enum.reverse 
      |> Enum.reduce("", fn x, acc -> # prepend to tail -- O(n)
           case acc do
             "" -> "(#{x})" <> acc
             _ -> "(#{x}) " <> acc # add space between terms
           end
         end)

    # Summary text finished now

    # "Game Over! Average Score: 6.4, # Games: 50, Scores: (ALARMING: 6) 
    # (BENZOLES: 7) (BICONVEXITY: 3) (BUFFETERS: 8) (BUSHFIRE: 6) (CANONISING: 5) 
    # (COEDUCATIONS: 3) (COOMBS: 8) (COSTUMER: 8) (DEPENDABLENESS: 3) 
    # (DISOBEDIENCES: 4) (FATHERLIKE: 4) (FAVORABLY: 7) (FLOPPIER: 10) (GELEE: 3) 
    # (GLARIER: 7) (GOBIOID: 4) (HOODIE: 8) (IMMANENCES: 4) (INVALIDITY: 5) (JESUITS: 7) 
    # (LANIARDS: 9) (LARVAL: 6) (MERCHANTED: 4) (MICROCLIMATIC: 3) (MOTIVATE: 6) 
    # (PEPLUMS: 25) (POLYMER: 6) (POSTNEONATAL: 3) (PTYALINS: 7) (RAINS: 7) 
    # (SHREWING: 8) (STABILIZING: 6) (STATELIEST: 4) (STROPHE: 5) (SUBLIMATE: 7) 
    # (SUNSCALD: 6) (SUSPENSER: 2) (SWITCHING: 9) (TASTEMAKERS: 4) (THERAPEUTIC: 2) 
    # (TRUSTED: 5) (UNDERNOURISHED: 4) (UNGOVERNABLE: 4) (UNHUSK: 25) (VERIFY: 7) 
    # (WEIGHTLESS: 5) (WHOEVER: 4) (WORSEN: 9) (WORSHIPING: 8)"
    
    
    "Game Over! Average Score: #{avg}, # Games: #{games}, Scores: #{scores}"
  end

end
