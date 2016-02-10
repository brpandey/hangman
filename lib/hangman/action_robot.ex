defmodule Hangman.Action.Robot do

	alias Hangman.{Game, Strategy, Player, Player.Events, Types.Game.Round}

  # Round Action function

  def action(%Player{} = player, :guess) do
  	
  	{name, strategy, game_no, seq_no} = Player.Round.params(player)

    round_info = 
	    case Strategy.make_guess(strategy) do
	      {:guess_word, guess_word} ->

	        {{^name, result, code, pattern, text}, final} =
	          Game.Server.guess_word(player.game_server_pid, guess_word)

	        Events.Notify.guessed_word(player.event_server_pid, 
	        	{name, game_no, guess_word})

	        Events.Notify.round_status(player.event_server_pid,
						{name, game_no, seq_no, text})

	       	%Round{seq_no: seq_no,
      			guess: guess_word, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}        

	      {:guess_letter, guess_letter} ->

	        {{^name, result, code, pattern, text}, final} =
	          Game.Server.guess_letter(player.game_server_pid, guess_letter)

					Events.Notify.guessed_letter(player.event_server_pid, 
						{name, game_no, guess_letter})

					Events.Notify.round_status(player.event_server_pid,
						{name, game_no, seq_no, text})

	        %Round{seq_no: seq_no,
      			guess: guess_letter, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}
	    end

	  Player.Round.update(player, round_info)
  end

end
