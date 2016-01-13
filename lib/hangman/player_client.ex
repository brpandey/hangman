defmodule Hangman.Player.Client do

  alias Hangman.{Player, Game, Reduction, Strategy, 
		Strategy.Options, Types.Game.Round}

	defstruct name: "", 
  	type: Nil,
    game_server_pid: Nil, 
    round_no: 0,
    round_choices: "",
    mystery_letter: Game.Server.mystery_letter,
    strategy: Strategy.new,
    round: %Round{},
    final_result: ""		

  @human :human
  @cyborg :cyborg
  @robot :robot

  @round_letter_choices 5


  # CREATE

  def new(name, type, game_server_pid) 
  	when is_binary(name) do

  	unless type in [@human, @cyborg, @robot], do: raise "unknown player type"

  	%Player.Client{ name: name, 
							type: type,
							game_server_pid: game_server_pid }
  end


  # READ

  def type_alias(%Player.Client{} = client, :star_wars) do
  	case client.type do
        @human -> :luke_skywalker
        @cyborg -> :darth_vader
        @robot -> :c3po      
        _ -> raise "unknown player type"
      end
  end

  def list_choices(%Player.Client{} = client) do
  	:human = client.type # assert

  	client.round_choices
  end

  def status(%Player.Client{} = client) do
  	
  	summary = client.round.final_result

		cond do
  		summary == [] or summary == "" ->
				client.round.status_text
  		
  		List.first(summary) == {:status, :game_over} ->
  			str_final_result(client)
  		
  		true -> "No status"
  	end
  end


  defp str_final_result(%Player.Client{} = client) do
  	
  	text = ""
  	summary = client.round.final_result

  	if List.first(summary) == {:status, :game_over} do
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

	def start(%Player.Client{} = client) do
    player = client.name

    {^player, :secret_length, secret_length} =
      Game.Server.secret_length(client.game_server_pid)

    client_action(client, client.type, {:game_start, secret_length})
  end

  def guess_letter(%Player.Client{} = client, letter) do
  	:human = client.type # assert

	  client_action(client, :human, {:guess_letter, letter})
  end

  def choose_letters(%Player.Client{} = client) do
  	:human = client.type # assert

  	client_action(client, :human, :choose_letters)
  end

  def robot_guess(%Player.Client{} = client, robot_guess_context) do
  	:robot = client.type # assert

  	client_action(client, :robot, robot_guess_context)
	end


  # PRIVATE 

  # Action functions

  defp client_action(%Player.Client{} = client, :robot, action_context) do
  	
  	client = action_setup(client, action_context)

  	{player, strategy, seq_no} = action_params(client)
    
    round_info = 
	    case Strategy.make_guess(strategy) do
	      {:guess_word, guess_word} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_word(client.game_server_pid, guess_word)

	       	%Round{seq_no: seq_no,
      			guess: guess_word, result: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}        

	      {:guess_letter, guess_letter} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_letter(client.game_server_pid, guess_letter)

	        %Round{seq_no: seq_no,
      			guess: guess_letter, result: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}
	    end

		update(%Player.Client{} = client, seq_no, round_info)
  end

  # Wrappers
  defp client_action(%Player.Client{} = client, :human, {:game_start, length}) do
  	client_action(client, {:human, :choose_letters}, {:game_start, length})
  end

  defp client_action(%Player.Client{} = client, :human, :choose_letters) do
  	client_action(client, {:human, :choose_letters}, Nil)
  end

  defp client_action(%Player.Client{} = client, 
  										{:human, :choose_letters}, action_context) do

  	client = action_setup(client, action_context)

  	{player, strategy, seq_no} = action_params(client)

  	# Return top 5 letters if possible
  	IO.inspect "strategy is: #{inspect strategy}"

  	counter = strategy.pass.tally

  	top_choices = Counter.most_common(counter, @round_letter_choices)

  	size = length(top_choices)

  	choices = "Player #{player}, Round #{seq_no}: " 
  			<> "please choose amongst these #{size} letter choices "
  			<> "observing their respective weighting: #{top_choices}"

  	client = Kernel.put_in(client.round_choices, choices)

  	client
  end


  defp client_action(%Player.Client{} = client, 
  							:human, {:guess_letter, guess_letter}) do

  	pass_counter = client.strategy.pass.tally
  	pid = client.game_server_pid

  	top5 = Counter.most_common_key(pass_counter, 5)

  	unless guess_letter in top5, do: {guess_letter, _} = hd(top5)

  	seq_no = client.seq_no + 1
  	player = client.player_name

  	{{^player, result, code, pattern, text}, final} =
      Game.Server.guess_letter(pid, guess_letter)

    round_info = %Round{seq_no: seq_no,
			guess: guess_letter, result: result, 
			status_code: code, pattern: pattern, 
			status_text: text, final_result: final}

		strategy = Strategy.update(client.strategy, guess_letter)
	  client = Kernel.put_in(client.strategy, strategy)

		update(client, seq_no, round_info)
  end


  # Helper functions

  defp update(%Player.Client{} = client, seq_no, %Round{} = round_info) do

  	client = Kernel.put_in(client.round, round_info)
	  client = Kernel.put_in(client.round_no, seq_no)

	  IO.puts "round: #{inspect round_info}"
    
    # TODO: Where in Player FSM to put?

    # Queue up the next event 
    # robot_guess(self(), {client.round.status_code, client.round.result})
    
    # Queue up the next next event, if game_over
    if round_info.final_result != "" and round_info.final_result != [] do
    	client = Kernel.put_in(client.final_result, 
    													round_info.final_result)
    
  		if Keyword.fetch!(round_info.final_result, :status) == :game_over do
  	
  			# TODO: Where in Player FSM to put?
  			# robot_guess(self(), :game_over)
			end
    end

    client
  end

  # Action helper functions

  defp action_params(%Player.Client{} = client) do

  	name = client.name
  	strategy = client.strategy
  	seq_no =  client.round_no + 1

  	{name, strategy, seq_no}
  end

  defp action_setup(%Player.Client{} = client, action_context) do

  	if action_context == Nil, do: action_context = action_context(client)

  	{player, strategy, seq_no} = action_params(client)

  	options = Keyword.new([{:id, player}, {:seq_no, seq_no}])

  	# Generate the word filter options for the words reduction engine
		filter_options = Options.filter_options(strategy, action_context)

		options = Keyword.merge(options, filter_options)

		match_key = Kernel.elem(action_context, 0)

		# Filter the engine hangman word set
		{^seq_no, reduction_pass_info} = Reduction.Engine.Stub.reduce(match_key, options)

		# Update the round strategy with the result of the reduction pass info _from the engine
		strategy = Strategy.update(strategy, reduction_pass_info)

	  client = Kernel.put_in(client.strategy, strategy)

    IO.puts "player setup action, printing strategy again: #{inspect client.strategy}"

    client
  end

  defp action_context(%Player.Client{} = client) do

  	case client.round.result do
  		:correct_letter -> 
  			{:correct_letter, client.round.guess, 
  					client.round.pattern, client.mystery_letter}

  		:incorrect_letter -> 
  			{:incorrect_letter, client.round.guess}
  	end
  end

end
