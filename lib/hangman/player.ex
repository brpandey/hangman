defmodule Hangman.Player do

  alias Hangman.{Player, Player.Round, Player.Events, 
                 Round.Action, Strategy, Game}
  
	defstruct name: "", 
  	type: nil,
    round_no: 0,
    round: %Hangman.Types.Game.Round{},
    strategy: Strategy.new,
    game_no: 0,
    game_summary: nil,
    game_server_pid: nil, 
  	event_server_pid: nil,    
    mystery_letter: Game.Server.mystery_letter

  @human :human
  @robot :robot

  # CREATE

  def new(name, type, game_pid, event_pid) 
  	when is_binary(name) and is_atom(type)
    and is_pid(game_pid) and is_pid(event_pid) do

  	unless type in [@human, @robot], do: raise "unknown player type"

  	%Player{ name: name, type: type, 
  		game_server_pid: game_pid, event_server_pid: event_pid }
  end

  # READ

  def last_word?(%Player{} = p) do
    case Strategy.last_word(p.strategy) do 
      {:guess_word, ""} -> false
      {:guess_word, _} -> true 
    end
  end

  def game_won?(%Player{} = p), do: p.round.status_code == :game_won
  def game_lost?(%Player{} = p), do: p.round.status_code == :game_lost
  def game_over?(%Player{} = p), do: p.game_summary != nil

  def game_summary(tuple_list) 
  when is_list(tuple_list) and is_tuple(Kernel.hd(tuple_list)) do
  	
		{:ok, avg} = Keyword.fetch(tuple_list, :average_score)
		{:ok, games} = Keyword.fetch(tuple_list, :games)
		{:ok, scores} = Keyword.fetch(tuple_list, :results)

		results = Enum.reduce(scores, "",  fn {k,v}, acc -> 
			acc <> " (#{k}: #{v})"  end)
			
		"Game Over! Average Score: #{avg}, " 
		<> "# Games: #{games}, Scores: #{results}"
	end

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
                        game_server_pid: player.game_server_pid,
                        event_server_pid: player.event_server_pid,
                        game_no: player.game_no + 1 }
    else
      player = Kernel.put_in(player.game_no, player.game_no + 1)

      # Notify the event server that we've started playing hangman
      Events.Server.notify_start(player.event_server_pid, player.name)
    end

    case player.type do
      @robot ->
        p = player |> Round.setup(:game_start) |> Action.action(:guess)

        {p, Round.status(p)}

      @human -> 
        p = player |> Round.setup(:game_start)
        choices = p |> Action.action(:choose_letters)

        {p, choices}

      _ -> raise "Unknown player type"
    end
	end

  # human choose letter
  def choose(%Player{} = p, :letter), do: choose(p, p.type, :letter)

	def choose(%Player{} = player, @human, :letter) do
  	p = player |> Round.setup
    choices = p |> Action.action(:choose_letters)
    {p, choices}
  end

  # robot guess letter
  def guess(%Player{} = p), do: guess(p, p.type)

	def guess(%Player{} = player, @robot) do
  	p = player |> Round.setup |> Action.action(:guess)

    {p, Round.status(p)}
	end


  # human guess last word
  def guess(%Player{} = p, :last_word), do: guess(p, p.type, :last_word)

	def guess(%Player{} = player, @human, :last_word) do
		p = player |> Action.action(:guess_last_word)

    {p, Round.status(p)}
	end


  # human guess letter
  def guess(%Player{} = p, l, :letter), do: guess(p, p.type, l, :letter)

	def guess(%Player{} = player, @human, letter, :letter)
  when is_binary(letter) do
		p = player |> Action.action(:guess_letter, letter)

    {p, Round.status(p)}
	end


  # DELETE

  def delete(%Player{} = _player), do:	%Player{}

end
