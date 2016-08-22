defmodule Hangman.Web.Handler do

  @moduledoc """
  Module drives `Player.Web.Controller`, while
  setting up the proper `Game` server and `Event` consumer states.

  Simply stated it politely nudges the player to proceed to the next 
  course of action or make the next guess.  The handler also collects 
  input from the user as necessary and displays data back to the 
  user.

  When the game is finished it politely ends the game playing.

  This module is the goto destination after all the arguments
  have been collected in `Hangman.Web`
  """

  alias Hangman.{Game.Pid.Cache, Player, Player.Web.Controller}

  require Logger

  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(Player.id, Player.kind, [String.t], boolean, boolean) :: :ok

  def run(name, :robot, secrets, log, false) when is_list(secrets) 
      and is_binary(hd(secrets)) and is_boolean(log) do
    {name, :robot, secrets, log, false} |> setup |> play 
  end

  @docp """
  Function setup loads the `player` specific `game` components.
  Setups the `game` server and per player `event` server.
  """
  
  @spec setup(tuple()) :: tuple
  defp setup({name, :robot, secrets, log, false}) when is_binary(name) 
  and is_list(secrets) and is_binary(hd(secrets)) and is_boolean(log) do
    
    # Grab game pid first from game pid cache
    game_pid = Cache.get_server_pid(name, secrets)

    Controller.start_worker(name, game_pid)

    logger_pid = 
      case log do
        true ->
          {:ok, pid} = Player.Logger.Supervisor.start_child(name)
          pid
        false -> nil
      end

    {name, logger_pid}
  end

  @docp """
  Play handles client play loop
  """

  @spec play(tuple) :: []
  defp play({player_handler_key, logger_pid}) do
    # atom tag on end for pipe ease

    # Loop until we have received an :exit value from the Player Controller
    list = Enum.reduce_while(Stream.cycle([player_handler_key]), [], fn key, acc ->
      
      feedback = key |> Controller.proceed

      case feedback do
        {code, _status} when code in [:begin, :transit] ->
          {:cont, acc}

        {:retry, _status} ->
          Process.sleep(2000) # Stop gap for now for no proc error by gproc
          {:cont, acc}

        {:action, status} -> # collect guess result status as given from action state
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          {:cont, acc}

        {:exit, status} -> 
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          Controller.stop_worker(key)
          if true == is_pid(logger_pid), do: Player.Logger.Handler.stop(logger_pid)
          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)

    # we reverse the prepended list of round statuses
    list |> Enum.reverse 

  end

end
