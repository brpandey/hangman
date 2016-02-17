defmodule Hangman.FSM.Test do
	use ExUnit.Case

  alias Hangman.{Cache, Player, Player.FSM}

	test "synchronous player through 1 game test" do
		
		{:ok, _pid} = Hangman.Supervisor.start_link()

		name = "wall_e"
		secrets = ["cumulate"]

 	  IO.puts "\n1) Starting regular WALL-e \n"		

		game_pid = Cache.get_server(name, secrets)

    {:ok, ppid} = 
      Player.Supervisor.start_child(game_pid, name, :robot)

		#:sys.trace(ppid, true)

		{:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "-------E; score=1; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid) 

    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)	    

    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)
    
    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:game_won, reply} = FSM.wall_e_guess(ppid)

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    {:game_over, reply} = FSM.wall_e_guess(ppid)

 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

    {:game_reset, reply} = FSM.wall_e_guess(ppid)

    IO.puts "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)"

    IO.puts "Asserts successfully passed, #{reply}"

 	  FSM.stop(ppid)


 	  # Game 2 -- ASYNC ROBOT!! turbo wall_e

 	  IO.puts "\n2) Starting turbo WALL-e \n"
		name = "turbo wall_e"
 	  
		secrets = ["cumulate"]

		game_pid = Cache.get_server(name, secrets)

    {:ok, ppid} = 
      Player.Supervisor.start_child(game_pid, name, :robot)

 	  IO.puts "\nturbo WALL-e....guessing \n"

		#:sys.trace(ppid, true)

		:ok = FSM.turbo_wall_e_guess(ppid)

		# sleep for 2 seconds :)
		receive do
			after 2000 -> nil
		end

		{_, reply} = FSM.sync_status(ppid)

		IO.puts "\nturbo WALL-e status: #{reply}"

		# Game 3 -- HUMAN!! socrates

 	  IO.puts "\n3) Starting Socrates human guessing player with 2 games \n"		

		name = "socrates"
 	  
		secrets = ["cumulate", "avocado"]

		game_pid = Cache.get_server(name, secrets)			

    {:ok, ppid} = 
      Player.Supervisor.start_child(game_pid, name, :human)

		#:sys.trace(ppid, true)

		reply = FSM.socrates_proceed(ppid)

		IO.puts "Game 1: #{inspect reply}"			

		reply = FSM.socrates_guess(ppid, "e")

		IO.puts "Game 1: #{inspect reply}"	

		reply = FSM.socrates_guess(ppid, "a")

		IO.puts "Game 1: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "t")

		IO.puts "Game 1: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "o")

		IO.puts "Game 1: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "i")

		IO.puts "Game 1: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "l")

		IO.puts "Game 1: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "c")

		IO.puts "Game 1: #{inspect reply}"

		assert {:game_choose_letter, "Player socrates, Round 8, C---LATE; score=7; status=KEEP_GUESSING. 3 weighted letter choices :  u:2 m*:1 p:1 (* robot choice)"} = reply

		reply = FSM.socrates_guess(ppid, "m")

    assert {:game_last_word, "Player socrates, Round 9: Last word left: cumulate"} = reply

		reply = FSM.socrates_win(ppid)

		IO.puts "Game 1: #{inspect reply}\n"

		reply = FSM.socrates_proceed(ppid)

		IO.puts "Game 2: #{inspect reply}"	

		reply = FSM.socrates_guess(ppid, "e")

		IO.puts "Game 2: #{inspect reply}"		

		reply = FSM.socrates_guess(ppid, "a")

		IO.puts "Game 2: #{inspect reply}"		

		reply = FSM.socrates_guess(ppid, "s")

		IO.puts "Game 2: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "r")

		IO.puts "Game 2: #{inspect reply}"

		reply = FSM.socrates_guess(ppid, "i")

		IO.puts "Game 2: #{inspect reply}"	

		reply = FSM.socrates_guess(ppid, "d")

		IO.puts "Game 2: #{inspect reply}"

		reply = FSM.socrates_win(ppid)

		IO.puts "Game 2: #{inspect reply}"

		reply = FSM.socrates_proceed(ppid)

		IO.puts "Game 2: #{inspect reply}"

		reply = FSM.socrates_proceed(ppid)

		IO.puts "Game 2: #{inspect reply}"
	end
end

