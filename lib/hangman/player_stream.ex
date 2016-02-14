defmodule Hangman.Player.Stream do

	alias Hangman.{Player.FSM}

	def get_rounds_lazy(name, game_pid, notify_pid) do
		Stream.resource(
			fn -> 
				{:ok, fsm_pid} = FSM.start(name, :robot, game_pid, notify_pid)
				fsm_pid
				end,

			fn fsm_pid ->
				case FSM.wall_e_guess(fsm_pid) do
					{:game_reset, _} -> {:halt, fsm_pid}

					# All other game states :game_keep_guessing ... :game_over
					{_, reply} -> {[reply], fsm_pid}							
				end
			end,
			
			fn fsm_pid -> FSM.stop(fsm_pid) end
		)
	end

end

