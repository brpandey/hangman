defmodule Hangman.FSM.Test do
	use ExUnit.Case

  alias Hangman.{Cache, Player.FSM}

	test "synchronous player through 1 game test" do
		
		{:ok, _pid} = Hangman.Supervisor.start_link()

		player_name = "julio"
		secrets = ["cumulate"]

		julio_game_server_pid = Cache.get_server(player_name, secrets)

		{:ok, julio_pid} = FSM.start(player_name, :robot, julio_game_server_pid)

		#:sys.trace(julio_pid, true)

		{:game_keep_guessing, reply} = FSM.r2d2_proceed(julio_pid)

    assert "-------E; score=1; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid) 

    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid)	    

    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid)
    
    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid)

    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid)

    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid)

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.r2d2_guess(julio_pid)

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:game_won, reply} = FSM.r2d2_guess(julio_pid)

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    FSM.r2d2_proceed(julio_pid)

 	  #assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

 	  FSM.stop(julio_pid)


 	  # Game 2 -- ASYNC ROBOT!! turbo r2d2
_ = """
			player_name = "julio"
 	  
		secrets = ["cumulate"]

		julio_game_server_pid = Cache.get_server(player_name, secrets)

		{:ok, julio_pid} = FSM.start(player_name, :robot, julio_game_server_pid)

		:sys.trace(julio_pid, true)

		reply = FSM.turbo_r2d2_proceed(julio_pid)

		IO.puts "start: #{inspect reply}"

		reply = FSM.sync_status(julio_pid)

		IO.puts "1 status: #{inspect reply}"
	"""

		# Game 3 -- HUMAN!! jedi

		player_name = "julio"
 	  
		secrets = ["cumulate", "avocado"]

		julio_game_server_pid = Cache.get_server(player_name, secrets)			

		{:ok, julio_pid} = FSM.start(player_name, :human, julio_game_server_pid)

		:sys.trace(julio_pid, true)

		reply = FSM.jedi_proceed(julio_pid)

		IO.puts "Game 1 start: #{inspect reply}"			

		reply = FSM.jedi_guess(julio_pid, "e")

		IO.puts "Game 1, round 1 status: #{inspect reply}"	

		reply = FSM.jedi_guess(julio_pid, "a")

		IO.puts "Game 1, round 2 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "t")

		IO.puts "Game 1, round 3 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "o")

		IO.puts "Game 1, round 4 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "i")

		IO.puts "Game 1, round 5 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "l")

		IO.puts "Game 1, round 6 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "c")

		IO.puts "Game 1, round 7 status: #{inspect reply}"

		assert "Player julio, Round 8, C---LATE; score=7; status=KEEP_GUESSING: please choose amongst these 3 letter choices observing their respective weighting:  u:2 m*:1 p:1. The asterisk denotes what the computer would have chosen"
			= reply

		reply = FSM.jedi_guess(julio_pid, "m")

		assert "Player julio, Round 9: Last word left: cumulate" = reply

		reply = FSM.jedi_win(julio_pid)

		IO.puts "Game 1, round 9 status: #{inspect reply}"

		reply = FSM.jedi_proceed(julio_pid)

		IO.puts "Game 2, start: #{inspect reply}"	

		reply = FSM.jedi_guess(julio_pid, "e")

		IO.puts "Game 2, round 1 status: #{inspect reply}"		

		reply = FSM.jedi_guess(julio_pid, "a")

		IO.puts "Game 2, round 2 status: #{inspect reply}"		

		reply = FSM.jedi_guess(julio_pid, "s")

		IO.puts "Game 2, round 3 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "r")

		IO.puts "Game 2, round 4 status: #{inspect reply}"

		reply = FSM.jedi_guess(julio_pid, "i")

		IO.puts "Game 2, round 5 status: #{inspect reply}"	

		reply = FSM.jedi_guess(julio_pid, "d")

		IO.puts "Game 2, round 6 status: #{inspect reply}"

		reply = FSM.jedi_win(julio_pid)

		IO.puts "Game 2, round 7 status: #{inspect reply}"

		reply = FSM.jedi_proceed(julio_pid)

		IO.puts "Game 2, status: #{inspect reply}"

	end
end

