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
    args |> setup |> start_player |> play |> cleanup
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

    {player_pid, game_pid, notify_pid}
  end
  

  def play({player_pid, game_pid, event_pid})
  when is_pid(player_pid) and is_pid(event_pid) do

    Enum.reduce_while(Stream.cycle([player_pid]), 0, fn pid, acc ->
      
      case Player.Server.proceed(pid) do
        {:ok, :guessing, status} -> 
          IO.puts "GUESSING status: {status}"
          {:cont, acc + 1}

        {:ok, :starting, status} -> 
          IO.puts "STARTING status: {status}"
          {:cont, acc + 1}

        {:ok, :exit, status} -> 
          IO.puts "EXIT status: {status}"
          Player.Server.stop(pid)
          {:halt, acc}

        _ ->
          raise "Unknown Player Server state abort"
      end
      
    end)

    {player_pid, game_pid, event_pid}
  end

  def cleanup({player_pid, game_pid, event_pid}) do
    Player.Server.stop(player_pid)
    Player.Events.stop(event_pid)
    Game.Server.stop(game_pid)
  end


  ### DEPRECATED

  def rounds_handler({name, game_pid, notify_pid}, @human) do

    # Wrap the player fsm game play in a stream
    # Stream resource returns an enumerable

    Stream.resource(
      fn -> 
        # Dynamically start hangman player
        player = start_player(name, @human, game_pid, notify_pid)
        {player, []}
        end,

      fn {ppid, code} ->

        case code do
          [] -> 
            {code, reply} = Player.proceed(player)
            {[reply], {ppid, code}}

          :game_choose_letter ->
            choice = IO.gets("[Please input letter choice] ")
            letter = String.strip(choice)
            {code, reply} = Player.FSM.socrates_guess(ppid, letter)

            case {code, reply} do
              {:game_reset, reply} -> 
                IO.puts "\n#{reply}"
                {:halt, ppid}
              _ -> {[reply], {ppid, code}}
            end
          
          :game_last_word ->
            {code, reply} = Player.FSM.socrates_win(ppid)

            case {code, reply} do
              {:game_reset, reply} -> 
                IO.puts "\n#{reply}"
                {:halt, ppid}
              _ -> {[reply], {ppid, code}}
            end

          :game_won -> 
            {code, reply} = Player.FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}

          :game_lost -> 
            {code, reply} = Player.FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}          

          :games_over -> 
            {:halt, ppid}

            #:games_over

        end
      end,
      
                    
      fn ppid -> 
        # Be a good functional citizen and cleanup server resources
        Player.Events.stop(notify_pid)
        Player.FSM.stop(ppid) 
      end
    )
  end

end
