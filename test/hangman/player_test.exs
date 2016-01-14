defmodule Hangman.Player.FSM.Test do
	use ExUnit.Case, async: true

	  alias Hangman.{Cache, Player}

		test "run a synchronous player through one game" do
			assert {:ok, _pid} = Hangman.Supervisor.start_link()

			player_name = "julio"
			secrets = ["cumulate"]

			julio_game_server_pid = Cache.get_server(player_name, secrets)

			{:ok, julio_pid} = Player.FSM.start_link(player_name, :robot, julio_game_server_pid)

			#:sys.trace(julio_pid, true)

			{:game_start, state, reply} = Player.FSM.robot_sync_start(julio_pid)

			#IO.puts "state: #{state}"

	    assert "-------E; score=1; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

	    {:game_keep_guessing, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

	    {:game_won, state, reply} = Player.FSM.robot_keep_guessing(julio_pid)

	    #IO.puts "state: #{state}"

	    assert "CUMULATE; score=8; status=GAME_WON" = reply

	    {:game_over, state, reply} = Player.FSM.robot_guess_sync(julio_pid, :game_won)

 	    #IO.puts "state: #{state}"


	 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

	 	  assert :ok = Player.FSM.stop(julio_pid)




	 	  # Game 2





	 	  
			secrets = ["cumulate"]

			^julio_game_server_pid = Cache.get_server(player_name, secrets)

			{:ok, julio_pid} = Player.FSM.start_link(player_name, :robot, julio_game_server_pid)


			:sys.trace(julio_pid, true)

			reply = Player.FSM.robot_async_start(julio_pid)

			IO.puts "start: #{inspect reply}"

			reply = Player.FSM.robot_status(julio_pid)

			IO.puts "1 status: #{inspect reply}"

			Player.FSM.robot_keep_guessing_async(julio_pid)
			
			reply = Player.FSM.robot_status(julio_pid)

			IO.puts "2 status: #{inspect reply}"

			Player.FSM.robot_keep_guessing_async(julio_pid)
			
			reply = Player.FSM.robot_status(julio_pid)

			IO.puts "3 status: #{inspect reply}"

			#Player.FSM.robot_keep_guessing_async(julio_pid)
			
			#reply = Player.FSM.robot_status(julio_pid)

			#IO.puts "4 status: #{inspect reply}"

		end
end

