defmodule Hangman.Player do

  alias Hangman.{Player, Player.Round, Player.Events, Strategy}

	defstruct name: "", 
  	type: nil,
    secret_length: nil,
    engine_server_pid: nil,
  	event_server_pid: nil,
    game_server_pid: nil, 
    game_no: 0,
    round_no: 0,
    mystery_letter: Hangman.Game.Server.mystery_letter,
    strategy: Strategy.new,
    round: %Hangman.Types.Game.Round{},
    game_summary: nil

  @human :human
  @robot :robot

  # CREATE

  def new(name, type, engine_pid, game_pid, event_pid) 
  	when is_binary(name) and is_atom(type) and is_pid(engine_pid) 
      and is_pid(game_pid) and is_pid(event_pid) do

  	unless type in [@human, @robot], do: raise "unknown player type"

  	%Player{ name: name, type: type, engine_server_pid: engine_pid, 
  		game_server_pid: game_pid, event_server_pid: event_pid }
  end

  # READ


  def last_word?(%Player{} = p) do
    case Strategy.last_word(p.strategy) do nil -> false; _ -> true end
  end

  def game_won?(%Player{} = p), do: p.round.status_code == :game_won
  def game_lost?(%Player{} = p), do: p.round.status_code == :game_lost
  def game_over?(%Player{} = p), do: p.game_summary != nil

  def status(%Player{} = p, :game_round), do: Round.status(p)

  def status(%Player{} = player, :game_over) do
  	case game_over?(player) do
  		true -> {:game_over, player.game_summary}
  		false -> {player.round.status_code, player.round.status_text}
  	end
  end


	# UPDATE

	def start(%Player{} = player) do
    if player.game_no >= 1 do
      player = %Player{ name: player.name, type: player.type, 
                        engine_server_pid: player.engine_server_pid,
                        game_server_pid: player.game_server_pid,
                        event_server_pid: player.event_server_pid,
                        game_no: player.game_no + 1 }
    else
      player = Kernel.put_in(player.game_no, player.game_no + 1)

      # Notify the event server that we've started playing hangman
      Events.Server.notify_start(player.event_server_pid, player.name)
    end

    Round.start(player)
  end

  def choose(%Player{} = p, :letter), do: Round.choose(p, p.type, :letter)
  def guess(%Player{} = p), do: Round.guess(p, p.type)
  def guess(%Player{} = p, :last_word), do: Round.guess(p, p.type, :last_word)
  def guess(%Player{} = p, l, :letter), do: Round.guess(p, p.type, l, :letter)

  # DELETE

  def delete(%Player{} = _player), do:	%Player{}

end
