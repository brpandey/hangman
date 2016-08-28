defmodule Hangman.CLI.Handler do

  @moduledoc """
  Module drives `Player.Controller`, while
  setting up the proper `Game` server and `Event` consumer states beforehand.

  Simply stated it politely nudges the player to proceed to the next 
  course of action or make the next guess.  The handler also collects 
  input from the user as necessary and displays data back to the 
  user.

  When the game is finished it politely ends the game playing.

  This module is the goto destination after all the arguments
  have been collected in `Hangman.CLI`
  """

  alias Hangman.{Game.Pid.Cache, Player, Player.Controller}

  require Logger


  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(String.t, Player.kind, [String.t], boolean, boolean) :: :ok
  def run(name, type, secrets, log, display, guess_timeout \\ 5000) when is_binary(name)
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) and is_integer(guess_timeout) do

    {name, type, secrets, log, display, guess_timeout} |> setup |> play
  end


  @docp """
  Function setup loads the `player` specific `game` components.
  Setups the `game` server and per player `event` server.
  """
  
  @spec setup(tuple()) :: tuple
  defp setup({name, type, secrets, log, display, timeout}) when is_binary(name) and
  is_list(secrets) and is_binary(hd(secrets)) and 
  is_boolean(log) and is_boolean(display) and is_integer(timeout) do
    
    # Grab game pid first from game pid cache
    game_pid = Cache.get_server_pid(name, secrets)

    Controller.start_worker(name, type, display, game_pid)

    logger_pid = 
      case log do
        true ->
          {:ok, pid} = Player.Logger.Supervisor.start_child(name)
          pid
        false -> nil
      end


    alert_pid = 
      case display do
        true ->
          {:ok, pid} = Player.Alert.Supervisor.start_child(name, self())
          pid
        false -> nil
      end

    {name, alert_pid, logger_pid, timeout}
  end

  @docp """
  Play handles client play loop
  """

  @spec play(tuple) :: :ok
  defp play({player_handler_key, alert_pid, logger_pid, timeout}) do 

    # Loop until we have received an :exit value from the Player Controller
    Enum.reduce_while(Stream.cycle([player_handler_key]), 0, fn key, acc ->
 
      feedback = key |> Controller.proceed

      # specifically handle IO for guess setup -- e.g. selection of letters
      feedback = handle_setup(key, feedback, timeout)

      case feedback do
        {code, _status} when code in [:begin, :action, :transit] ->
          {:cont, acc + 1}

        {:retry, _status} ->
          Process.sleep(2000) # Stop gap for now for no proc error by gproc when word not in dict
          {:cont, acc + 1}

        {:exit, _status} -> 
          Controller.stop_worker(key)
          if true == is_pid(alert_pid), do: Player.Alert.Handler.stop(alert_pid)
          if true == is_pid(logger_pid), do: Player.Logger.Handler.stop(logger_pid)
          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)

    :ok
  end

  # Helpers

  @spec handle_setup(Player.id, tuple, integer) :: tuple
  defp handle_setup(key, feedback, timeout) do
    # Handle feedback where the response code is :setup
    case feedback do
      {:setup, kw} ->

        {:ok, display} = Keyword.fetch(kw, :display)
        {:ok, choices} = Keyword.fetch(kw, :status)

        selection = ui(display, choices, timeout)
        key |> Controller.guess(selection)
      
      _ -> feedback # Pass back the passed in feedback
    end
  end


  @docp """
  If display is valid, show letter choices and also collect letter input
  """

  @spec ui(boolean, tuple, integer) :: tuple
  defp ui(display, {:guess_letter, text}, timeout)
  when is_boolean(display) and is_binary(text) do

    letter = 
      case display do
        true -> 
          IO.puts("\n#{text}")
          gets(timeout)
        
        false -> "" # If we aren't asking the user, the computer will select
      end
    
    {:guess_letter, letter}
  end


  defp ui(display, {:guess_word, last_word, text}, _timeout) 
  when is_boolean(display) and is_binary(text) do

    case display do
      true ->
        IO.puts("\n#{text}")
      false -> ""
    end

    {:guess_word, last_word}
  end

  @spec gets(integer) :: String.t
  defp gets(timeout) when is_integer(timeout) do

    task = 
      Task.async(fn ->
        {:ok, IO.gets("[Please input letter choice] ")}
      end)
    
    try do
      {:ok, choice} = Task.await(task, timeout)
      String.strip(choice) # return choice without newline
    catch
      :exit, {:timeout, _} ->
        " " # return space character
    end
    
  end

end
