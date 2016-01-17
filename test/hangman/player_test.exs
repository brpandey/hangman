defmodule Hangman.Player.FSM.Test do
	use ExUnit.Case

	  alias Hangman.{Cache, Player}


		test "synchronous player through 1 game test" do
			
			{:ok, _pid} = Hangman.Supervisor.start_link()

			player_name = "julio"
			secrets = ["cumulate"]

			julio_game_server_pid = Cache.get_server(player_name, secrets)

			{:ok, julio_pid} = Player.FSM.start(player_name, :robot, julio_game_server_pid)

			#:sys.trace(julio_pid, true)

			{:game_keep_guessing, reply} = Player.FSM.sync_start(julio_pid)

	    assert "-------E; score=1; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid) 

	    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid)	    

	    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid)
	    
	    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid)

	    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid)

	    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid)

	    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, reply} = Player.FSM.sync_guess(julio_pid)

	    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

	    {:game_won, reply} = Player.FSM.sync_guess(julio_pid)

	    assert "CUMULATE; score=8; status=GAME_WON" = reply

	    {:game_over, reply} = Player.FSM.sync_won(julio_pid)

	 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply


	 	  #Player.FSM.sync_game_over(julio_pid)
	 	  Player.FSM.stop(julio_pid)


	 	  # Game 2
 			player_name = "julio"
	 	  
			secrets = ["cumulate"]

			julio_game_server_pid = Cache.get_server(player_name, secrets)

			{:ok, julio_pid} = Player.FSM.start(player_name, :robot, julio_game_server_pid)

			:sys.trace(julio_pid, true)

			reply = Player.FSM.event_start(julio_pid)

			IO.puts "start: #{inspect reply}"

			reply = Player.FSM.sync_status(julio_pid)

			IO.puts "1 status: #{inspect reply}"

		end
end

