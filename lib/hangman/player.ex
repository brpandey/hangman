defmodule Hangman.Player do

  alias Hangman.{Player, Player.Round, Player.Events, Strategy}

	defstruct name: "", 
  	type: nil,
    secret_length: nil,
  	event_server_pid: nil,
    game_server_pid: nil, 
    game_no: 0,
    round_no: 0,
    round_choices: "",
    mystery_letter: Hangman.Game.Server.mystery_letter,
    strategy: Strategy.new,
    round: %Hangman.Types.Game.Round{},
    game_summary: nil

  @human :human
  @robot :robot

  # CREATE

  def new(name, type, game_server_pid, event_server_pid) 
  	when is_binary(name) and is_atom(type) do

  	unless type in [@human, @robot], do: raise "unknown player type"

  	%Player{ name: name, type: type, 
  		game_server_pid: game_server_pid, event_server_pid: event_server_pid }
  end

  # READ

  def list_choices(%Player{} = player) do
  	true = player.type in [@human] # assert
		player.round_choices
  end

  def last_word?(%Player{} = player) do
    case Strategy.last_word(player.strategy) do nil -> false; _ -> true end
  end

  def game_won?(%Player{} = player), do: player.round.status_code == :game_won

  def game_lost?(%Player{} = player), do: player.round.status_code == :game_lost

  def game_over?(%Player{} = player), do: player.game_summary != nil

  def round_status(%Player{} = player), do: Round.status(player)

  def game_over_status(%Player{} = player) do
  	case game_over?(player) do
  		true -> {:game_over, player.game_summary}
  		false -> {player.round.status_code, player.round.status_text}
  	end
  end


	# UPDATE

	def start(%Player{} = player) do
    if player.game_no >= 1 do
      player = %Player{ name: player.name, type: player.type, 
                        game_server_pid: player.game_server_pid,
                        event_server_pid: player.event_server_pid,
                        game_no: player.game_no + 1 }
    else
      player = Kernel.put_in(player.game_no, player.game_no + 1)

      # Notify the event server that we've started playing hangman
      Events.Notify.start(player.event_server_pid, player.name)
    end

    Round.start(player)
  end

  def choose_letters(%Player{} = player) do
  	true = player.type in [@human] # assert

  	Round.choose_letters(player)
  end

  def robot_guess(%Player{} = player) do
  	true = player.type in [@robot] # assert

  	Round.robot_guess(player)
	end

  def guess_letter(%Player{} = player, letter) do
  	true = player.type in [@human] # assert

  	Round.guess_letter(player, letter)
  end

  def guess_last_word(%Player{} = player) do
    true = player.type in [@human] # assert

    Round.guess_last_word(player)
  end

  # DELETE

  def delete(%Player{} = _player), do:	%Player{}

end
