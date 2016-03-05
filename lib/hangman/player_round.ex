defmodule Hangman.Player.Round do
  @moduledoc """
  Module to implement player game round abstraction.

  Works in conjuction with Hangman.Action and Hangman.Player
  to orchestrate actual round game play.

  Basic round functionality includes as setup, guess, update, status
  """

	alias Hangman.{Game, Pass, Strategy, Strategy.Options, 
                 Types.Game.Round, Types.Guess, Player, Player.Events}

  @type status_code :: :atom
  @type status_txt :: String.t

  @type result :: {status_code, status_txt}

	# READ

  @doc """
  Returns round context based on results of last guess
  """

  @spec context(Player.t) :: tuple | no_return
	def context(%Player{} = player) do

  	case player.round.result_code do
  		:correct_letter -> 
  			{:game_keep_guessing, :correct_letter, player.round.guess, 
  					player.round.pattern, player.mystery_letter}

  		:incorrect_letter -> 
  			{:game_keep_guessing, :incorrect_letter, player.round.guess}

      :incorrect_word ->
        {:game_keep_guessing, :incorrect_letter, " "}

  		true ->
  			raise Hangman.Error, "Unknown round result"
  	end
  end

  @doc """
  Returns round status tuple
  """

  @spec status(Player.t) :: result
  def status(%Player{} = player) do
		{player.round.status_code, player.round.status_text}
	end

  # UPDATE
  
  # Setup the game play round

  @doc """
  Setups game play round

  For game start stage, retrieves secret length from game server
  uses secret length to filter possible hangman words from pass server

  On subsequent rounds, generates a reduce key based on the result of the
  last guess to filter possible hangman words from word pass server
  """

  @spec setup(Player.t) :: Player.t
  def setup(%Player{} = player), do: setup(player, context(player))


  @spec setup(Player.t, :atom) :: Player.t
  def setup(%Player{} = player, :game_start) do

    name = player.name

    {^name, :secret_length, secret_length, status_text} =
      Game.Server.secret_length(player.game_server_pid)

    Events.Server.notify_length(player.event_server_pid,
      {name, player.game_no, secret_length})

    player = Kernel.put_in(player.round.status_code, :game_start)
    player = Kernel.put_in(player.round.status_text, status_text)

    true = is_number(secret_length) and secret_length > 0

    context = {:game_start, secret_length}

    setup(player, context)
  end

  @spec setup(Player.t, tuple) :: Player.t
  def setup(%Player{} = player, context) 
  when is_nil(context) == false do

  	{name, strategy, game_no, seq_no} = params(player)

  	pass_key = {name, game_no, seq_no}

  	# Generate the word filter options for the words reduction engine
		reduce_key = Options.reduce_key(strategy, context)

		match_key = Kernel.elem(context, 0)

		# Filter the engine hangman word set

		{^pass_key, pass_info} = 
      Pass.Server.get_pass(match_key, pass_key, reduce_key)

		# Update the round strategy with the result of the reduction pass info _from the engine
		strategy = Strategy.update(strategy, pass_info)
    
	  player = Kernel.put_in(player.strategy, strategy)

    player
  end


  @doc """
  Interjects round specific parameters into choices text
  """

  @spec augment_choices(Player.t, tuple) :: tuple
  def augment_choices(%Player{} = player, {code, choices_text})
  when is_binary(choices_text) do
    
  	{name, _strategy, _game_no, seq_no} = params(player)
    {_, status} = status(player)

    text = choices_text 
    |> String.replace("{name}", "#{name}")
    |> String.replace("{round_no}", "#{seq_no}")
    |> String.replace("{status}", "#{status}")
    
    {code, text}
  end


  @doc """
  Issues a client guess (either letter or word) against Game Server.
  Notifies player events server of guess results.

  Returns received round data
  """

  @spec guess(Player.t, Guess.t) :: Round.t
  def guess(%Player{} = player, {:guess_letter, letter})
  when is_binary(letter) do
    
  	{name, _strategy, game_no, seq_no} = params(player)

    {{^name, result, code, pattern, text}, final} =
	    Game.Server.guess_letter(player.game_server_pid, letter)
    
		Events.Server.notify_letter(player.event_server_pid, 
						                    {name, game_no, letter})
    
		Events.Server.notify_status(player.event_server_pid,
						                    {name, game_no, seq_no, text})
    
	  %Round{seq_no: seq_no,
      		 guess: letter, result_code: result, 
      		 status_code: code, pattern: pattern, 
      		 status_text: text, final_result: final}
  end

  @spec guess(Player.t, Guess.t) :: Round.t
  def guess(%Player{} = player, {:guess_word, word})
  when is_binary(word) do

  	{name, _strategy, game_no, seq_no} = params(player)

    {{^name, result, code, pattern, text}, final} =
	    Game.Server.guess_word(player.game_server_pid, word)
    
	  Events.Server.notify_word(player.event_server_pid, 
	        	                  {name, game_no, word})
    
	  Events.Server.notify_status(player.event_server_pid,
						                    {name, game_no, seq_no, text})

	  %Round{seq_no: seq_no,
      		 guess: word, result_code: result, 
      		 status_code: code, pattern: pattern, 
      		 status_text: text, final_result: final}      
  end


  @doc """
  Updates player abstraction with round results.  If games are over, updates
  games summary and notifies player events server.

  Under human guessing, player round update will update the strategy abstraction
  with the guess particulars.  If robot guessing, the strategy abstraction will also
  be updated.
  """

  @spec update(Player.t, Round.t, Guess.t) :: Player.t
  def update(%Player{} = player, %Round{} = round, {:guess_letter, letter}) do

    strategy = Strategy.update(player.strategy, {:guess_letter, letter})
	  update(player, round, strategy)
  end

  @spec update(Player.t, Round.t, Guess.t) :: Player.t
  def update(%Player{} = player, %Round{} = round, {:guess_word, word}) do

    strategy = Strategy.update(player.strategy, {:guess_word, word})
	  update(player, round, strategy)
  end

  @spec update(Player.t, Round.t, Strategy.t) :: Player.t
  def update(%Player{} = player, %Round{} = round, %Strategy{} = strategy) do

    player = Kernel.put_in(player.strategy, strategy)
	  update(player, round)
  end

  @spec update(Player.t, Round.t) :: Player.t
  def update(%Player{} = player, %Round{} = round) do

  	player = Kernel.put_in(player.round, round)
	  player = Kernel.put_in(player.round_no, round.seq_no)
       
    if (round.final_result != "" and round.final_result != [] and
    	List.first(round.final_result) == {:status, :games_over}) do

    	summary = Player.games_summary(round.final_result)
    	player = Kernel.put_in(player.games_summary, summary)

    	Events.Server.notify_games_over(player.event_server_pid, player.name, summary)
    end

    player
  end

  # Private

  # Helper

  # Returns round relevant data parameters

  @spec params(Player.t) :: tuple
  defp params(%Player{} = player) do

  	name = player.name
  	strategy = player.strategy
    game_no = player.game_no
    seq_no =  player.round_no + 1

  	{name, strategy, game_no, seq_no}
  end

end
