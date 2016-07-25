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

  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(String.t, Player.kind, [String.t], boolean, boolean) :: :ok
  def run(name, type, secrets, log, display) when is_binary(name)
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    args = {name, type, secrets, log, display}
    args |> setup |> start |> play

    System.halt(0)
  end


  @doc """
  Function setup loads the `player` specific `game` components.
  Setups the `game` server and per player `event` server.
  """
  
  @spec setup(String.t, [String.t], boolean, boolean) :: tuple
  def setup(name, type, secrets, log, display) when is_binary(name) and
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


  @doc "Start dynamic `player` child `worker`"
  
  @spec start(String.t, Player.kind, boolean, pid, pid) :: Supervisor.on_start_child
  def start({name, type, display, game_pid, notify_pid}) do
    {:ok, player_pid} = Player.Supervisor.start_child(name, type, display, 
                                                      game_pid, notify_pid)
    {player_pid, notify_pid}
  end
  

  def play({player_pid, notify_pid})
  when is_pid(player_pid) and is_pid(notify_pid) do

    Enum.reduce_while(Stream.cycle([player_pid]), 0, fn ppid, acc ->
      
      feedback = ppid |> Player.proceed
      feedback = handle_setup(ppid, feedback)

      case feedback do

        {:start, status} -> 
          IO.puts "START status: #{status}, acc: #{acc}"
          {:cont, acc + 1}

        {:action, status} -> 
          IO.puts "ACTION status: #{status}, acc: #{acc}"
          {:cont, acc + 1}

        {:stop, status} -> 
          IO.puts "STOP status: #{status}, acc: #{acc}"
          {:cont, acc + 1}

        {:exit, status} -> 
          IO.puts "EXIT status: #{status}, acc: #{acc}"
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

        IO.puts "SETUP status: display = #{display}, choices = #{inspect choices}"

        selection = ui(display, choices)
        ppid |> Player.guess(selection)

      _ -> feedback # Pass back the passed in feedback
    end
  end


  defp ui(display, {:guess_letter, text})
  when is_bool(display) and is_binary(text) do

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
  when is_bool(display) and is_binary(text) do

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
