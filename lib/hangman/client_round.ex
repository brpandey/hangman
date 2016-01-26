defmodule Hangman.Player.Client.Round do

	alias Hangman.{Game, Reduction, Strategy, 
		Strategy.Options, Types.Game.Round, Player.Events}

	@round_letter_choices 5

  def status(%Hangman.Player.Client{} = client) do
		{client.round.status_code, client.round.status_text}
	end

	def start(%Hangman.Player.Client{} = client) do

    client = do_start(client)

		context = {:game_start, client.secret_length}

    client
    	|> setup(context)
    	|> action(client.type, :guess)
	end

	def choose_letters(%Hangman.Player.Client{} = client) do

  	context = context(client)

  	client 
  		|> setup(context)
  		|> action(:human, :choose_letters)
	end

	def robot_guess(%Hangman.Player.Client{} = client) do
		
		context = context(client)

  	client
  	  |> setup(context)
  		|> action(:robot, :guess)
	end

	def guess_letter(%Hangman.Player.Client{} = client, letter) do
		client
  		|> action(:human, {:guess_letter, letter})
	end

	def guess_last_word(%Hangman.Player.Client{} = client) do
		client
    	|> action(:human, :guess_last_word)
	end

	# PRIVATE

	# READ

	defp context(%Hangman.Player.Client{} = client) do

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

  # UPDATE

  defp do_start(%Hangman.Player.Client{} = client) do
    
    player = client.name

    {^player, :secret_length, secret_length, status_text} =
      Game.Server.secret_length(client.game_server_pid)

    Events.Notify.secret_length(client.event_server_pid,
      {player, client.game_no, secret_length})
    
    client = Kernel.put_in(client.secret_length, secret_length)
    client = Kernel.put_in(client.round.status_code, :game_start)
    client = Kernel.put_in(client.round.status_text, status_text)

    client
  end

  defp setup(%Hangman.Player.Client{} = client, strategy_context) do

  	{player, strategy, game_no, seq_no} = params(client)

  	options = Keyword.new([{:id, player}, {:game_no, game_no}, {:seq_no, seq_no}])

  	# Generate the word filter options for the words reduction engine
		filter_options = Options.filter_options(strategy, strategy_context)

		options = Keyword.merge(options, filter_options)

		match_key = Kernel.elem(strategy_context, 0)

		# Filter the engine hangman word set
		{^seq_no, reduction_pass_info} = Reduction.Engine.Stub.reduce(match_key, options)

		# Update the round strategy with the result of the reduction pass info _from the engine
		strategy = Strategy.update(strategy, reduction_pass_info)

	  client = Kernel.put_in(client.strategy, strategy)

    client
  end

  # Round Action functions

  defp action(%Hangman.Player.Client{} = client, :robot, :guess) do
  	
  	{player, strategy, game_no, seq_no} = params(client)

    round_info = 
	    case Strategy.make_guess(strategy) do
	      {:guess_word, guess_word} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_word(client.game_server_pid, guess_word)

	        Events.Notify.guessed_word(client.event_server_pid, 
	        	{player, game_no, guess_word})

	        Events.Notify.round_status(client.event_server_pid,
						{player, game_no, seq_no, text})

	       	%Round{seq_no: seq_no,
      			guess: guess_word, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}        

	      {:guess_letter, guess_letter} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_letter(client.game_server_pid, guess_letter)

					Events.Notify.guessed_letter(client.event_server_pid, 
						{player, game_no, guess_letter})

					Events.Notify.round_status(client.event_server_pid,
						{player, game_no, seq_no, text})

	        %Round{seq_no: seq_no,
      			guess: guess_letter, result_code: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}
	    end

	  update(client, round_info)
  end

  # Wrappers
  defp action(%Hangman.Player.Client{} = client, :human, :guess) do
  	action(client, :human, :choose_letters)
  end

  defp action(%Hangman.Player.Client{} = client, :human, :choose_letters) do

  	{player, strategy, _game_no, seq_no} = params(client)

    choices = 
      case Strategy.last_word(strategy) do

        Nil ->
        	{_, status} = status(client)

        	# Return top 5 letter, count pairs if possible
        	top_choices = Strategy.most_common_letter_and_counts(strategy, 
                                  @round_letter_choices)

        	size = length(top_choices)

          choices_text = Enum.reduce(top_choices, "", fn {k,v}, acc -> 
            acc <> " #{k}:#{v}" end)

          best_letter = Strategy.retrieve_best_letter(strategy)

          choices_text = String.replace(choices_text, best_letter, best_letter <> "*")

        	"Player #{player}, Round #{seq_no}, #{status}. " <>
        	"#{size} weighted letter choices : #{choices_text}" <> 
          " (* robot choice)"
        
        last ->
          "Player #{player}, Round #{seq_no}: Last word left: #{last}"
      end

    client = Kernel.put_in(client.round_choices, choices)

  	client
  end

  defp action(%Hangman.Player.Client{} = client, :human, {:guess_letter, letter}) do

  	{player, strategy, game_no, seq_no} = params(client)

  	top_choices = Strategy.most_common_letter(strategy, @round_letter_choices)

    # If user has decided to put in a letter, not in the choices
    # grab the letter that had the highest letter counts
  	unless letter in top_choices, do: letter = Kernel.hd(top_choices)

  	{{^player, result, code, pattern, text}, final} =
      Game.Server.guess_letter(client.game_server_pid, letter)

    Events.Notify.guessed_letter(client.event_server_pid, 
    	{player, game_no, letter})

    Events.Notify.round_status(client.event_server_pid,
			{player, game_no, seq_no, text})

    round_info = %Round{seq_no: seq_no,
			guess: letter, result_code: result, 
			status_code: code, pattern: pattern, 
			status_text: text, final_result: final}

    strategy = Strategy.update(client.strategy, {:letter, letter})
	  client = Kernel.put_in(client.strategy, strategy)

		update(client, round_info)
  end

  defp action(%Hangman.Player.Client{} = client, :human, :guess_last_word) do

   	{player, strategy, game_no, seq_no} = params(client)

    last_word =
    	case Strategy.last_word(strategy) do Nil -> ""; word -> word end

    {{^player, result, code, pattern, text}, final} =
      Game.Server.guess_word(client.game_server_pid, last_word)

    Events.Notify.guessed_word(client.event_server_pid, 
  		{player, game_no, last_word})

    Events.Notify.round_status(client.event_server_pid,
			{player, game_no, seq_no, text})

    round_info = %Round{seq_no: seq_no,
      guess: last_word, result_code: result, 
      status_code: code, pattern: pattern, 
      status_text: text, final_result: final}

    strategy = Strategy.update(client.strategy, {:word, last_word})
    client = Kernel.put_in(client.strategy, strategy)

    update(client, round_info)
  end


  defp update(%Hangman.Player.Client{} = client, %Round{} = round_info) do

  	client = Kernel.put_in(client.round, round_info)
	  client = Kernel.put_in(client.round_no, round_info.seq_no)
       
    if (round_info.final_result != "" and round_info.final_result != [] and
    	List.first(round_info.final_result) == {:status, :game_over}) do

    	summary = str_game_summary(round_info.final_result)
    	client = Kernel.put_in(client.game_summary, summary)

    	Events.Notify.game_over(client.event_server_pid, client.name, summary)
    end

    client
  end

  # Action helper

  defp params(%Hangman.Player.Client{} = client) do

  	name = client.name
  	strategy = client.strategy
    game_no = client.game_no
    seq_no =  client.round_no + 1

  	{name, strategy, game_no, seq_no}
  end

  defp str_game_summary(tuple_list) 
  when is_list(tuple_list) and is_tuple(Kernel.hd(tuple_list)) do
  	
		{:ok, avg} = Keyword.fetch(tuple_list, :average_score)
		{:ok, games} = Keyword.fetch(tuple_list, :games)
		{:ok, scores} = Keyword.fetch(tuple_list, :results)

		results = Enum.reduce(scores, "",  fn {k,v}, acc -> 
								acc <> " (#{k}: #{v})"  end)
			
		"Game Over! Average Score: #{avg}, " 
			<> "# Games: #{games}, Scores: #{results}"
	end

end # Module Round