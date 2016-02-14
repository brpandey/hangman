defmodule Hangman.Player.Round do

	alias Hangman.{Game, Reduction, Strategy, 
		Strategy.Options, Types.Game.Round, Player, Player.Events, 
    Action.Robot, Action.Human}

  def status(%Player{} = player) do
		{player.round.status_code, player.round.status_text}
	end

	def start(%Player{} = player) do

    case player.type do
      :robot ->
        player
        |> do_start
        |> do_setup(:game_start)
        |> Robot.action(:guess)

      :human -> 
        player
        |> do_start
        |> do_setup(:game_start)
        |> Human.action(:choose_letters)

      _ -> raise "Unknown player type"
    end

	end

	def robot_guess(%Player{} = player) do
  	player
  	  |> do_setup
  		|> Robot.action(:guess)
	end

	def choose_letters(%Player{} = player) do
  	player 
  		|> do_setup
  		|> Human.action(:choose_letters)
	end

	def guess_letter(%Player{} = player, letter) do
		player
  		|> Human.action(:guess_letter, letter)
	end

	def guess_last_word(%Player{} = player) do
		player
    	|> Human.action(:guess_last_word)
	end



  # UPDATE

  def update(%Player{} = player, %Round{} = round_info) do

  	player = Kernel.put_in(player.round, round_info)
	  player = Kernel.put_in(player.round_no, round_info.seq_no)
       
    if (round_info.final_result != "" and round_info.final_result != [] and
    	List.first(round_info.final_result) == {:status, :game_over}) do

    	summary = do_game_summary(round_info.final_result)
    	player = Kernel.put_in(player.game_summary, summary)

    	Events.Notify.game_over(player.event_server_pid, player.name, summary)
    end

    player
  end


	# PRIVATE

	# READ

	defp do_context(%Player{} = player) do

  	case player.round.result_code do
  		:correct_letter -> 
  			{:game_keep_guessing, :correct_letter, player.round.guess, 
  					player.round.pattern, player.mystery_letter}

  		:incorrect_letter -> 
  			{:game_keep_guessing, :incorrect_letter, player.round.guess}

  		true ->
  			raise "Unknown round result"
  	end
  end

  # UPDATE

  defp do_start(%Player{} = player) do
    
    name = player.name

    {^name, :secret_length, secret_length, status_text} =
      Game.Server.secret_length(player.game_server_pid)

    Events.Notify.secret_length(player.event_server_pid,
      {name, player.game_no, secret_length})
    
    player = Kernel.put_in(player.secret_length, secret_length)
    player = Kernel.put_in(player.round.status_code, :game_start)
    player = Kernel.put_in(player.round.status_text, status_text)

    player
  end

  # Setup the game play round

  defp do_setup(%Player{} = player) do
    do_setup(player, do_context(player))
  end

  defp do_setup(%Player{} = player, :game_start) do
    len = secret_length(player)
    true = is_number(len)
    context = {:game_start, len}
    do_setup(player, context)
  end

  defp do_setup(%Player{} = player, context) when is_nil(context) == false do

  	{name, strategy, game_no, seq_no} = params(player)

  	pass_key = {name, game_no, seq_no}

  	# Generate the word filter options for the words reduction engine
		reduce_key = Options.reduce_key(strategy, context)

		match_key = Kernel.elem(context, 0)

		# Filter the engine hangman word set
		{^pass_key, pass_info} = 
      Reduction.Engine.Server.reduce(match_key, pass_key, reduce_key)

		# Update the round strategy with the result of the reduction pass info _from the engine
		strategy = Strategy.update(strategy, pass_info)

	  player = Kernel.put_in(player.strategy, strategy)

    player
  end


  # Helpers

  def params(%Player{} = player) do

  	name = player.name
  	strategy = player.strategy
    game_no = player.game_no
    seq_no =  player.round_no + 1

  	{name, strategy, game_no, seq_no}
  end

  defp secret_length(%Player{} = player) do
    player.secret_length
  end

  defp do_game_summary(tuple_list) 
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
