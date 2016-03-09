defmodule Player.Game do
  @moduledoc """
  Module handles relationship between 
  player, game server and player event server

  Supports both synchronous human and synchronous robot types

  Loads up player specific game components : 
  dynamic game server, and event server given player

  Manages specific player fsm behaviour (human or robot).

  Wraps fsm game play into an enumerable for easy running.
  """


  @human Player.human
  @robot Player.robot

  @doc """
  Function run connects all the player specific components together 
  and runs the player game
  """

  @spec run(String.t, Player.kind, [String.t], boolean, boolean) :: :ok
  def run(name, type, secrets, log, display) when is_binary(name)
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    fn_display = fn
      _, true -> 
        # if display arg is true then don't print out round status again
        "" 
      text, false -> 
        IO.puts("\n#{text}")
    end
    
    name 
    |> setup(secrets, log, display)
		|> rounds_handler(type)
		|> Stream.each(&fn_display.(&1, display))
		|> Stream.run
    
  end
  
  # Start dynamic player worker
  
  @spec start_player(String.t, Player.kind, pid, pid) :: Supervisor.on_start_child
  defp start_player(name, type, game_pid, notify_pid) do
    Player.Supervisor.start_child(name, type, game_pid, notify_pid)
  end
  
  # Function setup loads the player specific game components
  # Setup the game server and per player event server

  @spec setup(String.t, [String.t], boolean, boolean) :: tuple
  defp setup(name, secrets, log, display) when is_binary(name) and
  is_list(secrets) and is_binary(hd(secrets)) and 
  is_boolean(log) and is_boolean(display) do
    
    # Grab game pid first from game pid cache
	  game_pid = Game.Pid.Cache.get_server_pid(name, secrets)
    
    # Get event server pid next
    {:ok, notify_pid} = 
      Player.Events.Supervisor.start_child(log, display)

    {name, game_pid, notify_pid}
  end

  # Robot round playing!
  @spec rounds_handler(tuple, Player.kind) :: Enumerable.t
	defp rounds_handler({name, game_pid, notify_pid}, 
                       @robot) do

    # Wrap the player fsm game play in a stream
    # Stream resource returns an enumerable

		Stream.resource(
			fn -> 
        # Dynamically start hangman player
        {:ok, ppid} = start_player(name, @robot, game_pid, notify_pid)
        ppid
				end,

			fn ppid ->
				case Player.FSM.wall_e_guess(ppid) do
					{:game_reset, reply} -> 
            IO.puts "\n#{reply}"
            {:halt, ppid}
          
					# All other game states :game_keep_guessing ... :games_over
					{_, reply} -> {[reply], ppid}							
				end
        
			end,
			
			fn ppid -> 
        # Be a good functional citizen and cleanup server resources
        Player.Events.Server.stop(notify_pid)
        Player.FSM.stop(ppid) 
      end
		)
	end

  # Human round playing!
  @spec rounds_handler(tuple, Player.kind) :: Enumerable.t
	defp rounds_handler({name, game_pid, notify_pid}, @human) do

    # Wrap the player fsm game play in a stream
    # Stream resource returns an enumerable

		Stream.resource(
			fn -> 
        # Dynamically start hangman player
        {:ok, ppid} = start_player(name, @human, game_pid, notify_pid)
        {ppid, []}
				end,

			fn {ppid, code} ->

        case code do
          [] -> 
            {code, reply} = Player.FSM.socrates_proceed(ppid)
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
        Player.Events.Server.stop(notify_pid)
        Player.FSM.stop(ppid) 
      end
		)
	end

end
