defmodule Hangman.Player.Client do

  alias Hangman.{Player.Client, Game, Strategy}

	defstruct name: "", 
  	type: Nil,
    game_server_pid: Nil, 
    game_no: 0,
    round_no: 0,
    round_choices: "",
    mystery_letter: Game.Server.mystery_letter,
    strategy: Strategy.new,
    round: %Hangman.Types.Game.Round{},
    game_summary: []	

  @human :human
  @robot :robot


  # CREATE

  def new(name, type, game_server_pid) 
  	when is_binary(name) do

  	unless type in [@human, @robot], do: raise "unknown player type"

  	%Client{ name: name, type: type, game_server_pid: game_server_pid }
  end


  # READ

  def list_choices(%Client{} = client) do
  	true = client.type in [@human] # assert
  	client.round_choices
  end

  def last_word?(%Client{} = client) do
    last_word = Strategy.last_word(client.strategy)

    if last_word == Nil, do: false, else: true
  end

  def game_won?(%Client{} = client), do: client.round.status_code == :game_won
  def game_lost?(%Client{} = client), do: client.round.status_code == :game_lost

  def game_won_or_lost?(%Client{} = client) do 
    game_won?(client) or game_lost?(client)
  end

  def game_over?(%Client{} = client) do
  	List.first(client.game_summary) == {:status, :game_over}
  end

  def round_status(%Client{} = client) do
  	Client.Round.status(client)
  end

  def game_over_status(%Client{} = client) do
  	case game_over?(client) do
  		true -> {:game_over, str_final_result(client)}
  		false -> {client.round.status_code, client.round.status_text}
  	end
  end

  defp str_final_result(%Client{} = client) do
  	
  	text = ""

  	if game_over?(client) do
	  	summary = client.game_summary

			{:ok, avg} = Keyword.fetch(summary, :average_score)
			{:ok, games} = Keyword.fetch(summary, :games)
			{:ok, scores} = Keyword.fetch(summary, :results)

			results = Enum.reduce(scores, "", 
										fn({k,v}, acc) -> acc <> " (#{k}: #{v})"  end)
				
			text = "Game Over! Average Score: #{avg}, " 
						<> "# Games: #{games}, Scores: #{results}"
  	end

  	text
  end


	# UPDATE

	def start(%Client{} = client) do
    player = client.name
    type = client.type
    pid = client.game_server_pid
    game = client.game_no

    if client.game_no >= 1 do
      client = %Client{ name: player, type: type, 
                        game_server_pid: pid, game_no: game + 1 }
    else
      client = Kernel.put_in(client.game_no, client.game_no + 1)
    end

    {^player, :secret_length, secret_length} =
      Game.Server.secret_length(client.game_server_pid)

    context = {:game_start, secret_length}

    client 
    	|> Client.Round.setup(context)
    	|> Client.Round.action(client.type, :guess)
  end

  def choose_letters(%Client{} = client) do
  	true = client.type in [@human] # assert

  	context = Client.Round.context(client)

  	client 
  		|> Client.Round.setup(context) 
  		|> Client.Round.action(:human, :choose_letters)
  end

  def robot_guess(%Client{} = client) do
  	true = client.type in [@robot] # assert

  	context = Client.Round.context(client)

  	client
  	  |> Client.Round.setup(context) 
  		|> Client.Round.action(:robot, :guess)
	end

  def guess_letter(%Client{} = client, letter) do
  	true = client.type in [@human] # assert

  	client
  		|> Client.Round.action(:human, {:guess_letter, letter})
  end

  def guess_last_word(%Client{} = client) do
    true = client.type in [@human] # assert

    client
    	|> Client.Round.action(:human, :guess_last_word)
  end


  # DELETE

  def delete(%Client{} = _client) do
  	%Client{}
  end

end