defmodule Hangman.Player.Client do

  alias Hangman.{Player.Client, Player.Events, Strategy}

	defstruct name: "", 
  	type: Nil,
    secret_length: 0,
  	event_server_pid: Nil,
    game_server_pid: Nil, 
    game_no: 0,
    round_no: 0,
    round_choices: "",
    mystery_letter: Hangman.Game.Server.mystery_letter,
    strategy: Strategy.new,
    round: %Hangman.Types.Game.Round{},
    game_summary: Nil

  @human :human
  @robot :robot

  # CREATE

  def new(name, type, game_server_pid, event_server_pid) 
  	when is_binary(name) and is_atom(type) do

  	unless type in [@human, @robot], do: raise "unknown player type"

  	%Client{ name: name, type: type, 
  		game_server_pid: game_server_pid, event_server_pid: event_server_pid }
  end

  # READ

  def list_choices(%Client{} = client) do
  	true = client.type in [@human] # assert
		client.round_choices
  end

  def last_word?(%Client{} = client) do
    case Strategy.last_word(client.strategy) do Nil -> false; _ -> true end
  end

  def game_won?(%Client{} = client), do: client.round.status_code == :game_won

  def game_lost?(%Client{} = client), do: client.round.status_code == :game_lost

  def game_over?(%Client{} = client), do: client.game_summary != Nil

  def round_status(%Client{} = client), do: Client.Round.status(client)

  def game_over_status(%Client{} = client) do
  	case game_over?(client) do
  		true -> {:game_over, client.game_summary}
  		false -> {client.round.status_code, client.round.status_text}
  	end
  end


	# UPDATE

	def start(%Client{} = client) do
    if client.game_no >= 1 do
      client = %Client{ name: client.name, type: client.type, 
                        game_server_pid: client.game_server_pid,
                        event_server_pid: client.event_server_pid,
                        game_no: client.game_no + 1 }
    else
      client = Kernel.put_in(client.game_no, client.game_no + 1)

      # Notify the event server that we've started playing hangman
      Events.Notify.start(client.event_server_pid, client.name)
    end

    Client.Round.start(client)
  end

  def choose_letters(%Client{} = client) do
  	true = client.type in [@human] # assert

  	Client.Round.choose_letters(client)
  end

  def robot_guess(%Client{} = client) do
  	true = client.type in [@robot] # assert

  	Client.Round.robot_guess(client)
	end

  def guess_letter(%Client{} = client, letter) do
  	true = client.type in [@human] # assert

  	Client.Round.guess_letter(client, letter)
  end

  def guess_last_word(%Client{} = client) do
    true = client.type in [@human] # assert

    Client.Round.guess_last_word(client)
  end

  # DELETE

  def delete(%Client{} = _client), do:	%Client{}

end