defmodule Hangman.Player.Stream do

	alias Hangman.{Player.FSM}

	def round(name, game_pid, notify_pid) do
		Stream.resource(
			fn -> 
				{:ok, julio_pid} = FSM.start(name, :robot, game_pid, notify_pid)
				julio_pid
				end,

			fn julio_pid ->
				case FSM.wall_e_guess(julio_pid) do
					{:game_reset, _} -> {:halt, julio_pid}

					# All other game states :game_keep_guessing ... :game_over
					{_, reply} -> {[reply], julio_pid}							
				end
			end,
			
			fn julio_pid -> FSM.stop(julio_pid) end
		)
	end

end

