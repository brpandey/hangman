defmodule Hangman.Player.Handler do
  @moduledoc """

  Module drives `Player` server behaviour, while
  setting up the proper `Game` and `Event` state.

  Simply stated it politely nudges the player to proceed to the next 
  course of action or make the next guess.  The handler also collects 
  input from the user as necessary and displays data back to the 
  user.

  When the game is finished it politely ends the game playing.

  `Player.Handler` is the goto destination after all the arguments
  have been collected in `Player.CLI`
  """

  alias Hangman.{Player, Game, Dictionary}

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
    args |> setup |> start |> play(:cli)
  end

  def run(:web, name, :robot, secrets, log, display = false) when is_binary(name)
  and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    args = {name, :robot, secrets, log, display}
    args |> setup |> start |> play(:web) |> Enum.reverse 
    # we reverse the prepended list of round status
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

#   # Let's setup a trace for debug
#   :sys.trace(game_pid, true)
    
    # Get event server pid next
    {:ok, notify_pid} = 
      Player.Events.Supervisor.start_child(log, display)

    {name, type, display, game_pid, notify_pid}
  end


  @docp "Start dynamic `player` child `worker`"
  
  @spec start(tuple()) :: Supervisor.on_start_child
  defp start({name, type, display, game_pid, notify_pid}) do
    {:ok, player_pid} = Player.Supervisor.start_child(name, type, display, 
                                                      game_pid, notify_pid)
    {player_pid, notify_pid}
  end
  

  defp play({player_pid, notify_pid}, :cli) # atom tag on end for pipe ease
  when is_pid(player_pid) and is_pid(notify_pid) do

    Enum.reduce_while(Stream.cycle([player_pid]), 0, fn ppid, acc ->
      
      feedback = ppid |> Player.proceed
      feedback = handle_setup(ppid, feedback)

      case feedback do
        {code, _status} when code in [:start, :action, :stop] ->
          {:cont, acc + 1}

        {:exit, _status} -> 
          Player.stop(ppid)
          Player.Events.stop(notify_pid)
          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)
  end


  defp play({player_pid, notify_pid}, :web) # atom tag on end for pipe ease
  when is_pid(player_pid) and is_pid(notify_pid) do

    Enum.reduce_while(Stream.cycle([player_pid]), [], fn ppid, acc ->
      
      feedback = ppid |> Player.proceed
      feedback = handle_setup(ppid, feedback)

      case feedback do
        {code, _status} when code in [:start, :stop] ->
          {:cont, acc}

        {:action, status} -> 
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          {:cont, acc}

        {:exit, status} -> 
          acc = [status | acc] # prepend to list then later reverse -- O(1)
          Player.stop(ppid)
          Player.Events.stop(notify_pid)
          {:halt, acc}

        _ -> raise "Unknown Player state"
      end
    end)
  end

  # Helpers

  defp handle_setup(ppid, feedback) do
    # Handle feedback where the response code is :setup
    case feedback do
      {:setup, kw} ->

        {:ok, display} = Keyword.fetch(kw, :display)
        {:ok, choices} = Keyword.fetch(kw, :status)

        selection = ui(display, choices)
        ppid |> Player.guess(selection)

      _ -> feedback # Pass back the passed in feedback
    end
  end


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
