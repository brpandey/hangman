defmodule Hangman.Client.Handler do
  @moduledoc """

  Module drives `Player.Controller` server behaviour, while
  setting up the proper `Game` server and `Event` consumer states.

  Simply stated it politely nudges the player to proceed to the next 
  course of action or make the next guess.  The handler also collects 
  input from the user as necessary and displays data back to the 
  user.

  When the game is finished it politely ends the game playing.

  `Client.Handler` is the goto destination after all the arguments
  have been collected in `Player.CLI`
  """

  alias Hangman.{Player, Game, Dictionary}

  require Logger

  @max_random_words_request 10

  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(atom, String.t, Player.kind, [String.t], boolean, boolean) :: :ok
  def run(:cli, name, type, secrets, log, display) when is_binary(name)
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    args = {name, type, secrets, log, display}
    args |> setup |> play(:cli)

  end

  def run(:web, name, :robot, secrets, log, display = false) when is_binary(name)
  and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    args = {name, :robot, secrets, log, display}
    args |> setup |> play(:web) 
  end

  @docp """
  Function setup loads the `player` specific `game` components.
  Setups the `game` server and per player `event` server.
  """
  
  @spec setup(tuple()) :: tuple
  defp setup({name, type, secrets, log, display}) when is_binary(name) and
  is_list(secrets) and is_binary(hd(secrets)) and 
  is_boolean(log) and is_boolean(display) do
    
    # Grab game pid first from game pid cache
    game_pid = Game.Pid.Cache.get_server_pid(name, secrets)

    Player.Controller.start_worker(name, type, display, game_pid)

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

    {name, alert_pid, logger_pid}
  end

  @docp """
  Play handles client play loop
  """

  @spec play(tuple, atom) :: :ok
  defp play({player_handler_key, alert_pid, logger_pid}, :cli) do 
    # atom tag on end for pipe ease

    # Loop until we have received an :exit value from the Player Controller
    Enum.reduce_while(Stream.cycle([player_handler_key]), 0, fn key, acc ->
 
      feedback = key |> Player.Controller.proceed

      # specifically handle IO for guess setup -- e.g. selection of letters
      feedback = handle_setup(key, feedback)

      case feedback do
        {code, _status} when code in [:begin, :action, :transit, :retry] ->
          {:cont, acc + 1}

        {:exit, _status} -> 
          Player.Controller.stop_worker(key)
          if true == is_pid(alert_pid), do: Player.Alert.Handler.stop(alert_pid)
          if true == is_pid(logger_pid), do: Player.Logger.Handler.stop(logger_pid)
          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)

    :ok
  end


  @spec play(tuple, atom) :: [...]
  defp play({player_handler_key, alert_pid, logger_pid}, :web) do
    # atom tag on end for pipe ease

    # Loop until we have received an :exit value from the Player Controller
    list = Enum.reduce_while(Stream.cycle([player_handler_key]), [], fn key, acc ->
      
      feedback = key |> Player.Controller.proceed
      # specifically handle IO for guess setup -- e.g. selection of letters
      feedback = handle_setup(key, feedback)

      case feedback do
        {code, _status} when code in [:begin, :transit, :retry] ->
          {:cont, acc}

        {:action, status} -> # collect guess result status as given from action state
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          {:cont, acc}

        {:exit, status} -> 
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          Player.Controller.stop_worker(key)
          if true == is_pid(alert_pid), do: Player.Alert.Handler.stop(alert_pid)
          if true == is_pid(logger_pid), do: Player.Logger.Handler.stop(logger_pid)
          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)

    # we reverse the prepended list of round statuses
    list |> Enum.reverse 

  end

  # Helpers

  @spec handle_setup(Player.id, tuple) :: tuple
  defp handle_setup(key, feedback) do
    # Handle feedback where the response code is :setup
    case feedback do
      {:setup, kw} ->

        {:ok, display} = Keyword.fetch(kw, :display)
        {:ok, choices} = Keyword.fetch(kw, :status)

        selection = ui(display, choices)
        key |> Player.Controller.guess(selection)
      
      _ -> feedback # Pass back the passed in feedback
    end
  end


  @docp """
  If display is valid, show letter choices and also collect letter input
  """

  @spec ui(boolean, tuple) :: tuple
  defp ui(display, {:guess_letter, text})
  when is_boolean(display) and is_binary(text) do

    letter = 
      case display do
        true -> 
          IO.puts("\n#{text}")
          choice = IO.gets("[Please input letter choice] ")
          String.strip(choice)
        false -> "" # If we aren't asking the user, the computer will select
      end
    
    {:guess_letter, letter}
  end


  defp ui(display, {:guess_word, last_word, text}) 
  when is_boolean(display) and is_binary(text) do

    case display do
      true ->
        IO.puts("\n#{text}")
      false -> ""
    end

    {:guess_word, last_word}
  end

  @doc "Returns random word secrets given count"
  @spec random(String.t) :: [String.t] | no_return
  def random(count) do
    # convert user input to integer value
    value = String.to_integer(count)
    cond do
      value > 0 and value <= @max_random_words_request ->
        Dictionary.Cache.lookup(:random, value)
      true ->
        raise HangmanError, "submitted random count value is not valid"
    end
  end
end
