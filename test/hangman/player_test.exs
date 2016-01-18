defmodule Hangman.FSM.Test do
	use ExUnit.Case

	require Hangman.Supervisor
	require Hangman.Cache
	require Hangman.Player.FSM

  alias Hangman.{Cache, Player.FSM}


	test "synchronous player through 1 game test" do
		
		{:ok, _pid} = Hangman.Supervisor.start_link()

		player_name = "julio"
		secrets = ["cumulate"]

		julio_game_server_pid = Cache.get_server(player_name, secrets)

		{:ok, julio_pid} = FSM.start(player_name, :robot, julio_game_server_pid)

		#:sys.trace(julio_pid, true)

		{:game_keep_guessing, reply} = FSM.sync_start(julio_pid)

    assert "-------E; score=1; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid) 

    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid)	    

    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid)
    
    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid)

    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid)

    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid)

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.sync_guess(julio_pid)

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:game_won, reply} = FSM.sync_guess(julio_pid)

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    {:game_over, reply} = FSM.sync_won(julio_pid)

 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply


 	  #FSM.sync_game_over(julio_pid)
 	  FSM.stop(julio_pid)


 	  # Game 2 -- ASYNC ROBOT!! turbo_r2d2
_ = """
			player_name = "julio"
 	  
		secrets = ["cumulate"]

		julio_game_server_pid = Cache.get_server(player_name, secrets)

		{:ok, julio_pid} = FSM.start(player_name, :robot, julio_game_server_pid)

		:sys.trace(julio_pid, true)

		reply = FSM.event_start(julio_pid)

		IO.puts "start: #{inspect reply}"

		reply = FSM.sync_status(julio_pid)

		IO.puts "1 status: #{inspect reply}"
	"""

		# Game 3 -- HUMAN!! jedi

			player_name = "julio"
 	  
		secrets = ["cumulate"]

		julio_game_server_pid = Cache.get_server(player_name, secrets)			

		{:ok, julio_pid} = FSM.start(player_name, :human, julio_game_server_pid)

		:sys.trace(julio_pid, true)

		reply = FSM.human_start(julio_pid)

		IO.puts "start: #{inspect reply}"			

		reply = FSM.human_status(julio_pid)

		IO.puts "1 status: #{inspect reply}"



	end
end

