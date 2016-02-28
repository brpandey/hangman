defmodule Hangman.Player.Game do

	alias Hangman.{Game, Player.FSM}

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
		|> play_rounds_lazy(type)
		|> Stream.each(&fn_display.(&1, display))
		|> Stream.run
    
  end
  
  # Start
  defp start_player(name, type, game_pid, notify_pid) do
    Hangman.Player.Supervisor.start_child(name, type, game_pid, notify_pid)
  end
  
  # Setup the game pid and per game event server
  defp setup(name, secrets, log, display) when is_binary(name) and
  is_list(secrets) and is_binary(hd(secrets)) and 
  is_boolean(log) and is_boolean(display) do
    
    # Grab game pid first
	  game_pid = Game.Pid.Cache.Server.get_server_pid(name, secrets)
    
    # Get event server pid next
    {:ok, notify_pid} = 
      Hangman.Player.Events.Supervisor.start_child(log, display)

    {name, game_pid, notify_pid}
  end

  # Robot round playing!
	defp play_rounds_lazy({name, game_pid, notify_pid}, 
                       :robot) do
		Stream.resource(
			fn -> 
        {:ok, ppid} = start_player(name, :robot, game_pid, notify_pid)
        ppid
				end,

			fn ppid ->
				case FSM.wall_e_guess(ppid) do
					{:game_reset, reply} -> 
            IO.puts "#{reply}"
            {:halt, ppid}
          
					# All other game states :game_keep_guessing ... :game_over
					{_, reply} -> {[reply], ppid}							
				end
        
			end,
			
			fn ppid -> 
        Hangman.Player.Events.Server.stop(notify_pid)
        FSM.stop(ppid) 
      end
		)
	end

  # Human round playing!
	defp play_rounds_lazy({name, game_pid, notify_pid}, :human) do
		Stream.resource(
			fn -> 
        {:ok, ppid} = start_player(name, :human, game_pid, notify_pid)
        {ppid, []}
				end,

			fn {ppid, code} ->

        case code do
          [] -> 
            {code, reply} = FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}

          :game_choose_letter ->
            choice = IO.gets("[Please input letter choice] ")
            letter = String.strip(choice)
            {code, reply} = FSM.socrates_guess(ppid, letter)

				    case {code, reply} do
					    {:game_reset, reply} -> 
                IO.puts "#{reply}"
                {:halt, ppid}
              _ -> {[reply], {ppid, code}}
            end
          
          :game_last_word ->
            {code, reply} = FSM.socrates_win(ppid)

				    case {code, reply} do
					    {:game_reset, reply} -> 
                IO.puts "#{reply}"
                {:halt, ppid}
              _ -> {[reply], {ppid, code}}
            end

          :game_won -> 
            {code, reply} = FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}

          :game_lost -> 
            {code, reply} = FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}          

          :game_over -> 
            {:halt, ppid}

            :game_over

				end
			end,
			
			fn ppid -> 
        Hangman.Player.Events.Server.stop(notify_pid)
        FSM.stop(ppid) 
      end
		)
	end

end
