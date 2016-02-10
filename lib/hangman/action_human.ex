defmodule Hangman.Action.Human do

	alias Hangman.{Game, Strategy, Player, Player.Events, Types.Game.Round}

	@human_letter_choices 5

  # Round Action functions

  def action(%Player{} = player, :guess_last_word) do

   	{name, strategy, game_no, seq_no} = Player.Round.params(player)

    last_word =
    	case Strategy.last_word(strategy) do Nil -> ""; word -> word end

    {{^name, result, code, pattern, text}, final} =
      Game.Server.guess_word(player.game_server_pid, last_word)

    Events.Notify.guessed_word(player.event_server_pid, 
  		{name, game_no, last_word})

    Events.Notify.round_status(player.event_server_pid,
			{name, game_no, seq_no, text})

    round_info = %Round{seq_no: seq_no,
      guess: last_word, result_code: result, 
      status_code: code, pattern: pattern, 
      status_text: text, final_result: final}

    strategy = Strategy.update(player.strategy, {:word, last_word})
    player = Kernel.put_in(player.strategy, strategy)

    Player.Round.update(player, round_info)
  end

  def action(%Player{} = player, :choose_letters) do

  	{name, strategy, _game_no, seq_no} = Player.Round.params(player)

    choices = 
      case Strategy.last_word(strategy) do

        Nil ->
        	{_, status} = Player.Round.status(player)

        	# Return top 5 letter, count pairs if possible
        	top_choices = Strategy.most_common_letter_and_counts(strategy, 
                                  @human_letter_choices)

        	size = length(top_choices)

          choices_text = Enum.reduce(top_choices, "", fn {k,v}, acc -> 
            acc <> " #{k}:#{v}" end)

          best_letter = Strategy.retrieve_best_letter(strategy)

          choices_text = String.replace(choices_text, best_letter, best_letter <> "*")

        	"Player #{name}, Round #{seq_no}, #{status}. " <>
        	"#{size} weighted letter choices : #{choices_text}" <> 
          " (* robot choice)"
        
        last ->
          "Player #{name}, Round #{seq_no}: Last word left: #{last}"
      end

    player = Kernel.put_in(player.round_choices, choices)

  	player
  end

  def action(%Player{} = player, :guess_letter, letter)
  when is_binary(letter) do

  	{name, strategy, game_no, seq_no} = Player.Round.params(player)

  	top_choices = Strategy.most_common_letter(strategy, @human_letter_choices)

    # If user has decided to put in a letter, not in the choices
    # grab the letter that had the highest letter counts
  	unless letter in top_choices, do: letter = Kernel.hd(top_choices)

  	{{^name, result, code, pattern, text}, final} =
      Game.Server.guess_letter(player.game_server_pid, letter)

    Events.Notify.guessed_letter(player.event_server_pid, 
    	{name, game_no, letter})

    Events.Notify.round_status(player.event_server_pid,
			{name, game_no, seq_no, text})

    round_info = %Round{seq_no: seq_no,
			guess: letter, result_code: result, 
			status_code: code, pattern: pattern, 
			status_text: text, final_result: final}

    strategy = Strategy.update(player.strategy, {:letter, letter})
	  player = Kernel.put_in(player.strategy, strategy)

		Player.Round.update(player, round_info)
  end

end
