defmodule Hangman.Flow.Shard.Handler do

  @moduledoc """
  Module runs game play for the given shard of secrets
  as determined by `Flow`.  Basically, runs a chunk
  of the overall original secrets vector.

  Module drives `Player.Controller`, while
  setting up the proper `Game` server and `Event` consumer states beforehand.

  Simply stated it politely nudges the player to proceed to the next 
  course of action or make the next guess.  

  When the game is finished it politely ends the game playing return the 
  shard_key and game snapshot tuple.

  The twist to this is that these shard handlers are run
  in parallel and concurrently thanks to the concurrent map reduce
  setup of `Flow`
  """

  alias Hangman.{Game.Pid.Cache, Player, Player.Controller}

  require Logger

  @sleep 3000

  @doc """
  Sets up the `game` server and per player `event` server.
  Used primarly by the collation logic in Flow
  """
  
  @spec setup({Player.id, list[String.t]}) :: Player.id
  def setup({id, secrets}) when 
  (is_binary(id) or is_tuple(id)) and is_list(secrets) do

    # Grab game pid first from game pid cache
    game_pid = Cache.get_server_pid(id, secrets)

    # Start Worker in Controller
    Controller.start_worker(id, :robot, false, game_pid)

    id
  end

  @doc """
  Play handles client play loop for particular player shard_key 
  """

  @spec play(Player.id) :: {Player.id, list(String.t)}
  def play(shard_key) do

    # Loop until we have received an :exit value from the Player Controller
    list = Enum.reduce_while(Stream.cycle([shard_key]), [], fn key, acc ->
      
      feedback = key |> Controller.proceed

      case feedback do
        {code, _status} when code in [:begin, :transit] ->
          {:cont, acc}

        {:retry, _status} ->
          Process.sleep(@sleep) # Stop gap for now for no proc error by gproc
          {:cont, acc}

        {:action, status} -> # collect guess result status as given from action state
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          {:cont, acc}

        {:exit, status} -> 
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          Controller.stop_worker(key)

          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)

    # we reverse the prepended list of round statuses
    list = list |> Enum.reverse

    {shard_key, list}
  end


end
