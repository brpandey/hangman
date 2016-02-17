defmodule Hangman.Player.Game do

	alias Hangman.{Cache, Player.FSM}

  defp start_player(name, type, game_pid) do
    Hangman.Player.Supervisor.start_child(name, type, game_pid)
  end

  def setup(name, secrets) when is_binary(name) and
  is_list(secrets) and is_binary(hd(secrets)) do
	  game_pid = Cache.get_server(name, secrets)
    {name, game_pid}
  end

	def play_rounds_lazy({name, game_pid}, :robot) do
		Stream.resource(
			fn -> 
        {:ok, ppid} = start_player(name, :robot, game_pid)
        ppid
				end,

			fn ppid ->
				case FSM.wall_e_guess(ppid) do
					{:game_reset, _} -> {:halt, ppid}

					# All other game states :game_keep_guessing ... :game_over
					{_, reply} -> {[reply], ppid}							
				end
			end,
			
			fn ppid -> FSM.stop(ppid) end
		)
	end


	def play_rounds_lazy({name, game_pid}, :human) do
		Stream.resource(
			fn -> 
        {:ok, ppid} = start_player(name, :human, game_pid)
        {ppid, []}
				end,

			fn {ppid, code} ->
        case code do
          [] -> 
            {code, reply} = FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}

          :game_choose_letter ->
            choice = IO.gets("[Please input letter choice] ")
            letter = String.strip(choice)
            {code, reply} = FSM.socrates_guess(ppid, letter)
            {[reply], {ppid, code}}
          
          :game_last_word ->
            {code, reply} = FSM.socrates_win(ppid)
            {[reply], {ppid, code}}

          :game_won -> 
            {code, reply} = FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}

          :game_lost -> 
            {code, reply} = FSM.socrates_proceed(ppid)
            {[reply], {ppid, code}}          

          :game_over -> 
            {:halt, ppid}

				end
			end,
			
			fn ppid -> FSM.stop(ppid) end
		)
	end

end
