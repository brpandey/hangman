defmodule Hangman.Player.Game do
  @moduledoc """
  Module handles game playing for synchronous `human` and `robot`
  player types. Handles relationship between 
  `Player.FSM`, `Game.Server` and `Player.Events`

  Loads up the `player` specific `game` components: 
  a dynamic `game` server, and a dynamic `event` server

  Manages specific `player` fsm behaviour (`human` or `robot`).
  Wraps fsm game play into an enumerable for easy running.
  """

  alias Hangman.{Player, Game}

  @doc """
  Function run connects all the `player` specific components together 
  and runs the player `game`
  """

  @spec run(String.t, Player.kind, [String.t], boolean, boolean) :: :ok
  def run(name, type, secrets, log, display) when is_binary(name)
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    args = {name, type, secrets, log, display}
    args |> setup |> start_player |> play

    System.halt(0)
  end

  # for Web playing
  @spec web_run(String.t, Player.kind, [String.t], boolean, boolean) :: :ok
  def web_run(name, type, secrets, log, _display) do
    run(name, type, secrets, log, false)
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

#    # Let's setup a trace for debug
#    :sys.trace(game_pid, true)
    
    # Get event server pid next
    {:ok, notify_pid} = 
      Player.Events.Supervisor.start_child(log, display)

    {name, type, display, game_pid, notify_pid}
  end


  @doc "Start dynamic `player` child `worker`"
  
  @spec start_player(String.t, Player.kind, boolean, pid, pid) :: Supervisor.on_start_child
  def start_player({name, type, display, game_pid, notify_pid}) do
    {:ok, player_pid} = Player.Supervisor.start_child(name, type, display, 
                                               game_pid, notify_pid)
    {player_pid, notify_pid}
  end
  

  def play({player_pid, notify_pid})
  when is_pid(player_pid) and is_pid(notify_pid) do

    Enum.reduce_while(Stream.cycle([player_pid]), 0, fn ppid, acc ->
      
      feedback = Player.Server.proceed(ppid)
      feedback = handle_guess_setup(ppid, feedback)

      case feedback do

        {:starting, status} -> 
          IO.puts "STARTING status: {status}, acc: #{acc}"
          {:cont, acc + 1}

        {:guess_action, status} -> 
          IO.puts "GUESS ACTION status: #{status}, acc: #{acc}"
          {:cont, acc + 1}

        {:stopped, status} -> 
          IO.puts "STOPPED status: {status}, acc: #{acc}"
          {:cont, acc + 1}

        {:exit, status} -> 
          IO.puts "EXIT status: #{status}, acc: #{acc}"
          Player.Server.stop(ppid)
          Player.Events.stop(notify_pid)
          {:halt, acc}

        _ -> raise "Unknown Player Server state"
      end

    end)

  end


  def handle_guess_setup(ppid, feedback) do
    # Handle feedback where the response code is :guess_setup
    case feedback do
      {:guess_setup, status} ->

          case status do
            [] ->  Player.Server.proceed(ppid)              
            {display, choices} -> 
              IO.puts "GUESS SETUP status: display = #{display}, choices = #{choices}"
              guess = ui(display, choices)
              Player.Server.proceed(ppid, guess)
          end
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

end
