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

		reply = FSM.human_guess(julio_pid, "e")

		IO.puts "1 status: #{inspect reply}"	

		reply = FSM.human_guess(julio_pid, "a")

		IO.puts "2 status: #{inspect reply}"

		reply = FSM.human_guess(julio_pid, "t")

		IO.puts "3 status: #{inspect reply}"

		reply = FSM.human_guess(julio_pid, "o")

		IO.puts "4 status: #{inspect reply}"

		reply = FSM.human_guess(julio_pid, "i")

		IO.puts "5 status: #{inspect reply}"

		reply = FSM.human_guess(julio_pid, "l")

		IO.puts "6 status: #{inspect reply}"

		reply = FSM.human_guess(julio_pid, "c")

		IO.puts "7 status: #{inspect reply}"

		assert "Player julio, Round 8: please choose amongst these 3 letter choices observing their respective weighting:  u:2 m*:1 p:1. The asterisk denotes what the computer would have chosen"
			= reply

		reply = FSM.human_guess(julio_pid, "m")

		IO.puts "8 status: #{inspect reply}"

		reply = FSM.human_guess(julio_pid, "u")

		IO.puts "9 status: #{inspect reply}"
	end
end

