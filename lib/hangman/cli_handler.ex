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

  alias Hangman.{Game, Player, Handler.Loop}
  import Loop
  require Logger

  # 3 secs
  @sleep 3000

  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(String.t(), Player.kind(), [String.t()], boolean, boolean) :: :ok
  def run(name, type, secrets, log, display, guess_timeout \\ 10)
      when is_binary(name) and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) and
             is_boolean(log) and is_boolean(display) and is_integer(guess_timeout) do
    {name, type, secrets, log, display, guess_timeout} |> setup |> play
  end

  # Function setup loads the `player` specific `game` components.
  # Setups the `game` server and per player `event` server.

  @spec setup({binary, atom, list, boolean, boolean, pos_integer}) :: tuple
  defp setup({name, type, secrets, log, display, timeout})
       when is_binary(name) and is_list(secrets) and is_binary(hd(secrets)) and is_boolean(log) and
              is_boolean(display) and is_integer(timeout) do
    # Grab game pid first from game server controller
    game_pid = Game.Server.Controller.get_server(name, secrets)

    Player.Controller.start_worker(name, type, display, game_pid)

    logger_pid =
      case log do
        true ->
          {:ok, pid} = Player.Logger.Supervisor.start_child(name)
          pid

        false ->
          nil
      end

    alert_pid =
      case display do
        true ->
          {:ok, pid} = Player.Alert.Supervisor.start_child(name, self())
          pid

        false ->
          nil
      end

    {name, alert_pid, logger_pid, timeout}
  end

  # Play handles client play loop

  @spec play({String.t(), pid, pid, pos_integer}) :: :ok
  defp play({player_key, alert_pid, logger_pid, timeout}) do
    # Loop until we have received an :exit value from the Player Controller

    while true do
      feedback = Player.Controller.proceed(player_key)

      # specifically handle IO for guess setup -- e.g. selection of letters
      case handle_setup(player_key, feedback, timeout) do
        {code, _status} when code in [:begin, :action] ->
          :ok

        # display the single game overs and game summaries
        {:transit, status} ->
          IO.puts("\n#{status}")

        {:retry, _status} ->
          # Stop gap for now for no proc error by gproc when word not in dict
          Process.sleep(@sleep)

        {:exit, _status} ->
          Player.Controller.stop_worker(player_key)
          Game.Server.Controller.stop_server(player_key)

          _ = if is_pid(alert_pid), do: Player.Alert.Handler.stop(alert_pid)
          _ = if is_pid(logger_pid), do: Player.Logger.Handler.stop(logger_pid)

          break()

        _ ->
          raise "Unknown Player state"
      end
    end

    :ok
  end

  # Helpers

  # Handles setup of round by extracting human guess from ui
  # Else return original feedback tuple

  @spec handle_setup(Player.id(), tuple, integer) :: tuple
  defp handle_setup(key, feedback, timeout) do
    # Handle feedback where the response code is :setup
    case feedback do
      {:setup, kw} ->
        {:ok, choices} = Keyword.fetch(kw, :status)
        selection = ui(choices, timeout)
        key |> Player.Controller.guess(selection)

      # Pass back the passed in feedback
      _ ->
        feedback
    end
  end

  # If display is valid, show letter choices and also collect letter input

  @spec ui(Guess.options(), pos_integer) :: Guess.t()
  defp ui({:guess_letter, text}, timeout) when is_binary(text) do
    IO.puts("\n#{text}")
    letter = gets(timeout)

    {:guess_letter, letter}
  end

  defp ui({:guess_word, last_word, text}, _timeout) when is_binary(text) do
    IO.puts("\n#{text}")

    {:guess_word, last_word}
  end

  # Starts a task to run the IO.gets function as a background process.  
  # Uses the timeout facility to load a dummy guess value.  
  # Timeout value is arg specified

  @spec gets(integer) :: String.t()
  defp gets(timeout) when is_integer(timeout) do
    task =
      Task.async(fn ->
        {:ok, IO.gets("[Please input letter choice] ")}
      end)

    try do
      {:ok, choice} = Task.await(task, timeout)
      # return choice without newline
      String.strip(choice)
    catch
      :exit, {:timeout, _} ->
        # return space character
        " "
    end
  end
end
