defmodule Hangman.Player.Client do

  alias Hangman.{Player.Client, Game, Reduction, Strategy, 
		Strategy.Options, Types.Game.Round}

	defstruct name: "", 
  	type: Nil,
    game_server_pid: Nil, 
    round_no: 0,
    round_choices: "",
    mystery_letter: Game.Server.mystery_letter,
    strategy: Strategy.new,
    round: %Round{},
    game_summary: []	

  @human :human
  @robot :robot

  @round_letter_choices 5


  # CREATE

  def new(name, type, game_server_pid) 
  	when is_binary(name) do

  	unless type in [@human, @robot], do: raise "unknown player type"

  	%Client{ name: name, type: type, game_server_pid: game_server_pid }
  end


  # READ

  def fun_type_alias(%Client{} = client, :star_wars) do
  	case client.type do
        @human -> :jedi
        @robot -> :r2d2
        _ -> raise "unknown player type"
      end
  end

  def list_choices(%Client{} = client) do
  	true = client.type in [@human] # assert

  	client.round_choices
  end

  def game_won?(%Client{} = client) do
  	client.round.status_code == :game_won
  end

  def game_lost?(%Client{} = client) do
  	client.round.status_code == :game_lost
  end

  def game_won_or_lost?(%Client{} = client) do
  	game_won?(client) or game_lost?(client)
  end

  def game_over?(%Client{} = client) do
  	List.first(client.game_summary) == {:status, :game_over}
  end

  def round_status(%Client{} = client) do
  	{client.round.status_code, client.round.status_text}
  end

  def game_over_status(%Client{} = client) do

  	case game_over?(client) do
  		true -> {:game_over, str_final_result(client)}
  		false -> {client.round.status_code, client.round.status_text}
  	end
  end

  def server_pull_status(%Client{} = client) do

  	player = client.name
  	
  	{^player, status_code, status_text} =
  		Game.Server.game_status(client.game_server_pid)

  	if status_code == :game_reset do
    	round_info = %Round{ status_code: status_code, status_text: status_text }
			client = Kernel.put_in(client.round, round_info)
			client = Kernel.put_in(client.game_summary, [status_code])
		end

  	client
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

    {^player, :secret_length, secret_length} =
      Game.Server.secret_length(client.game_server_pid)

    round_action(client, client.type, {:game_start, secret_length})
  end

  def guess_letter(%Client{} = client, letter) do
  	true = client.type in [@human] # assert

	  round_action(client, :human, {:guess_letter, letter})
  end

  def choose_letters(%Client{} = client) do
  	true = client.type in [@human] # assert

  	round_action(client, :human, :choose_letters)
  end

  def robot_guess(%Client{} = client, robot_guess_context) do
  	true = client.type in [@robot] # assert

  	round_action(client, :robot, robot_guess_context)
	end


  # PRIVATE 

  # UPDATE

  # Round Action functions

  defp round_action(%Client{} = client, :robot, context) do
  	
  	client = round_setup(client, context)

  	{player, strategy, seq_no} = round_params(client)

    round_info = 
	    case Strategy.make_guess(strategy) do
	      {:guess_word, guess_word} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_word(client.game_server_pid, guess_word)

	       	%Round{seq_no: seq_no,
      			guess: guess_word, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}        

	      {:guess_letter, guess_letter} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_letter(client.game_server_pid, guess_letter)

	        %Round{seq_no: seq_no,
      			guess: guess_letter, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}
	    end

	  round_update(client, seq_no, round_info)
  end

  # Wrappers
  defp round_action(%Client{} = client, :human, {:game_start, length}) do
  	round_action(client, {:human, :choose_letters}, {:game_start, length})
  end

  defp round_action(%Client{} = client, :human, :choose_letters) do
  	round_action(client, {:human, :choose_letters}, Nil)
  end

  defp round_action(%Client{} = client, {:human, :choose_letters}, context) do

  	client = round_setup(client, context)

  	{player, strategy, seq_no} = round_params(client)

  	# Return top 5 letter, count pairs if possible
  	top_choices = Strategy.most_common_letter_and_counts(strategy, 
                            @round_letter_choices)

  	size = length(top_choices)

    choices_text = Enum.reduce(top_choices, "", fn {k,v}, acc -> 
      acc <> " #{k}:#{v}" end)

    best_letter = Strategy.retrieve_best_letter(strategy)

    choices_text = String.replace(choices_text, best_letter, best_letter <> "*")

  	choices = "Player #{player}, Round #{seq_no}: " 
  			<> "please choose amongst these #{size} letter choices "
  			<> "observing their respective weighting: #{choices_text}."
        <> " The asterisk denotes what the computer would have chosen"

  	client = Kernel.put_in(client.round_choices, choices)

  	client
  end


  defp round_action(%Client{} = client, :human, {:guess_letter, letter}) do

  	pid = client.game_server_pid

  	top_choices = Strategy.most_common_letter(client.strategy, 
                            @round_letter_choices)

  	unless letter in top_choices, do: letter = hd(top_choices)

  	seq_no = client.round_no + 1
  	player = client.name

  	{{^player, result, code, pattern, text}, final} =
      Game.Server.guess_letter(pid, letter)

    round_info = %Round{seq_no: seq_no,
			guess: letter, result_code: result, 
			status_code: code, pattern: pattern, 
			status_text: text, final_result: final}

		strategy = Strategy.update(client.strategy, letter)
	  client = Kernel.put_in(client.strategy, strategy)

		round_update(client, seq_no, round_info)
  end


  defp round_update(%Client{} = client, seq_no, %Round{} = round_info) do

  	client = Kernel.put_in(client.round, round_info)
	  client = Kernel.put_in(client.round_no, seq_no)
       
    if (round_info.final_result != "" and round_info.final_result != [] and
    	List.first(round_info.final_result) == {:status, :game_over}) do
    
    	client = Kernel.put_in(client.game_summary, round_info.final_result)
    end

    client
  end

  defp round_setup(%Client{} = client, context) do

  	if context == Nil, do: context = round_filter_context(client)

  	{player, strategy, seq_no} = round_params(client)

  	options = Keyword.new([{:id, player}, {:seq_no, seq_no}])

  	# Generate the word filter options for the words reduction engine
		filter_options = Options.filter_options(strategy, context)

		options = Keyword.merge(options, filter_options)

		match_key = Kernel.elem(context, 0)

		# Filter the engine hangman word set
		{^seq_no, reduction_pass_info} = Reduction.Engine.Stub.reduce(match_key, options)

		# Update the round strategy with the result of the reduction pass info _from the engine
		strategy = Strategy.update(strategy, reduction_pass_info)

	  client = Kernel.put_in(client.strategy, strategy)

    client
  end


  # Action helper functions

  defp round_params(%Client{} = client) do

  	name = client.name
  	strategy = client.strategy
  	seq_no =  client.round_no + 1

  	{name, strategy, seq_no}
  end  

  defp round_filter_context(%Client{} = client) do

  	case client.round.result_code do
  		:correct_letter -> 
  			{:correct_letter, client.round.guess, 
  					client.round.pattern, client.mystery_letter}

  		:incorrect_letter -> 
  			{:incorrect_letter, client.round.guess}

  		:incorrect_word -> 
  			{:incorrect_word, client.round.guess}

  		true ->
  			raise "Unknown round result"
  	end
  end

end