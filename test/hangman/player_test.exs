defmodule Hangman.Player.Test do
	use ExUnit.Case, async: true

	  alias Hangman.{Cache, Player}

		test "run a synchronous player through one game" do
			assert {:ok, _pid} = Hangman.Supervisor.start_link()

			player_name = "julio"
			secrets = ["cumulate"]

			julio_game_server_pid = Cache.get_server(player_name, secrets)

			{:ok, julio_pid} = Player.start_link(player_name, julio_game_server_pid)

			#:sys.trace(julio_pid, true)

			reply = Player.robot_guess_sync(julio_pid, :game_start)

	    assert "-------E; score=1; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :correct_letter})

	    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :correct_letter})

	    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :correct_letter})

	    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :incorrect_letter})

	    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :incorrect_letter})

	    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :correct_letter})

	    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :correct_letter})

	    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

	    reply = Player.robot_guess_sync(julio_pid, {:game_keep_guessing, :correct_letter})

	    assert "CUMULATE; score=8; status=GAME_WON" = reply

	    reply = Player.robot_guess_sync(julio_pid, :game_over)

	 	  assert [status: :game_over, average_score: 8.0, games: 1, results: [{"CUMULATE", 8}]] = reply

		end
end

