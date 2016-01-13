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

			reply = Player.FSM.robot_start(julio_pid)

	    assert "-------E; score=1; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

	    reply = Player.FSM.robot_keep_guessing(julio_pid)

	 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

#	    assert "CUMULATE; score=8; status=GAME_WON" = reply

	    reply = Player.FSM.robot_guess_sync(julio_pid, :game_over)

	 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

	 	  assert :ok = Player.FSM.stop(julio_pid)

	 	  """
			secrets = ["avocado"]

			^julio_game_server_pid = Cache.get_server(player_name, secrets)

			{:ok, julio_pid} = Player.FSM.start_link(player_name, julio_game_server_pid)

			reply = Player.FSM.human_start(julio_pid)

			IO.puts "start: #{reply}"

			"""
		end
end

