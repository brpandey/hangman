defmodule Hangman.Player.Game do

	alias Hangman.{Player.FSM}

	def play_rounds_lazy(:robot, game_pid, player_name) do

		Stream.resource(
			fn -> 
        {:ok, robot_player_pid} = 
          Hangman.Player.Supervisor.start_child(game_pid, player_name, :robot)
        robot_player_pid
				end,

			fn robot_player_pid ->
				case FSM.wall_e_guess(robot_player_pid) do
					{:game_reset, _} -> {:halt, robot_player_pid}

					# All other game states :game_keep_guessing ... :game_over
					{_, reply} -> {[reply], robot_player_pid}							
				end
			end,
			
			fn robot_player_pid -> FSM.stop(robot_player_pid) end
		)
	end

end

