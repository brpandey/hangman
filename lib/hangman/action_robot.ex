defmodule Hangman.Action.Robot do

	alias Hangman.{Game, Strategy, Player, Player.Events, Types.Game.Round}

  # Round Action function

  def action(%Player{} = player, :guess) do
  	
  	{name, strategy, game_no, seq_no} = Player.Round.params(player)
    {strategy, strategy_guess} = Strategy.make_guess(strategy)

    round_info = 
	    case strategy_guess do
	      {:guess_word, guess_word} ->

	        {{^name, result, code, pattern, text}, final} =
	          Game.Server.guess_word(player.game_server_pid, guess_word)

	        Events.Server.notify_word(player.event_server_pid, 
	        	{name, game_no, guess_word})

	        Events.Server.notify_status(player.event_server_pid,
						{name, game_no, seq_no, text})

	       	%Round{seq_no: seq_no,
      			guess: guess_word, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}        

	      {:guess_letter, guess_letter} ->

	        {{^name, result, code, pattern, text}, final} =
	          Game.Server.guess_letter(player.game_server_pid, guess_letter)

					Events.Server.notify_letter(player.event_server_pid, 
						{name, game_no, guess_letter})

					Events.Server.notify_status(player.event_server_pid,
						{name, game_no, seq_no, text})

	        %Round{seq_no: seq_no,
      			guess: guess_letter, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}
	    end

    player = Kernel.put_in(player.strategy, strategy)
	  Player.Round.update(player, round_info)
  end

end