defmodule Hangman.Shard.Handler do
  @moduledoc """
  Module runs game play for the given shard of secrets
  as determined by `Shard.Flow`.  Basically, runs a chunk
  of the overall original secrets vector.

  Module drives `Player.Controller`, while
  setting up the proper `Game` server and `Event` consumer states beforehand.

  Simply stated it politely nudges the player to proceed to the next 
  course of action or make the next guess.  

  When the game is finished it politely ends the game playing returning the 
  shard_key and game snapshot tuple.

  The twist to this is that these shard handlers are run
  in parallel and concurrently thanks to the concurrent map reduce
  setup of `Flow`
  """

  alias Hangman.{Game, Player, Handler.Accumulator}
  import Accumulator
  require Logger

  @sleep 3000

  @doc """
  Sets up the `game` server and per player `event` server.
  Used primarly by the collation logic in Flow
  """
  
  @spec setup({Player.id, list[String.t]}) :: Player.id
  def setup({id, secrets}) when 
  (is_binary(id) or is_tuple(id)) and is_list(secrets) do

    # Grab game pid first from game server controller
    game_pid = Game.Server.Controller.get_server(id, secrets)

    # Start Worker in Controller
    Player.Controller.start_worker(id, :robot, false, game_pid)

    id
  end

  @doc """
  Play handles client play loop for particular player shard_key 
  """

  @spec play(Player.id) :: {Player.id, list(String.t)}
  def play(shard_key) do

    # Compose game status accumulator until we have received 
    # an :exit value from the Player Controller
    list = repeatedly do

      case Player.Controller.proceed(shard_key) do
        {code, _status} when code in [:begin, :transit] -> :ok

        {:retry, _status} -> 
          Process.sleep(@sleep) # Stop gap for gproc no proc error

        {:action, status} -> 
          next(status) # collect action guess result

        {:exit, status} -> 
          # Stop both the player client worker and the corresponding game server
          Player.Controller.stop_worker(shard_key)
          Game.Server.Controller.stop_server(shard_key)            
          
          done(status) # signal end of accumulator and capture last status result
        
          _ -> raise "Unknown Player state"
      end

    end        

    {shard_key, list}
  end


end
