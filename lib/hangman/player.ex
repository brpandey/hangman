defmodule Hangman.Player do
  @behaviour :gen_fsm

 	alias Hangman.Strategy, as: Strategy
 	alias Hangman.GameServer, as: GameServer
 	alias Hangman.WordEngine, as: WordEngine


  defmodule State do
    defstruct player_name: "", 
      game_server_pid: Nil, 
      word_engine_pid: Nil,
      
      #TODO: Move into a separate struct, e.g. GamePlay
      last_guess: "",
      current_guess: "",
      current_guess_result: Nil, 
      current_game_status: Nil, 
      current_pattern: "", 
      current_status_text: "",
      
      final_result: ""
  end

  # External API
  def start_link(player_name, game_server_pid, word_engine_pid) do
    :gen_fsm.start_link(__MODULE__, 
      {player_name, game_server_pid, word_engine_pid}, [])
  end

  # Events

  # 1) start guessing
  def robot_guess(player_pid, event = :game_reset) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 2) keep guessing, last letter correct
  def robot_guess(player_pid, event = {:game_keep_guessing, :correct_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 3) keep guessing, last letter incorrect
  def robot_guess(player_pid, event = {:game_keep_guessing, :incorrect_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 4) game won
  def robot_guess(player_pid, event = {:game_won, guess_result}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 5) game lost
  def robot_guess(player_pid, event = {:game_lost, guess_result}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 6) game_over
  def robot_guess(player_pid, event = :game_over) do
    :gen_fsm.send_event(player_pid, event)
  end

  # Callbacks

  def init(player_name, game_server_pid, word_engine_pid) do

    state = %State{player_name: player_name, 
                    game_server_pid: game_server_pid, 
                    word_engine_pid: word_engine_pid}

    robot_guess(self(), :game_start)
    
    { :ok, :guessing_robot, state }

  end

  # GUESSING_ROBOT state

  def guessing_robot(:game_reset, state) do 
  	IO.puts "GAME RESET STATE"
  end

  # 1) start
  def guessing_robot(:game_start, state) do

    IO.puts "In State: guessing_robot :game_start"

    player = state.player_name

    {^player, :secret_length, secret_length} =
      GameServer.secret_length(state.game_server_pid)

    {^player, :game_keep_guessing, status} = 
			GameServer.game_status(state.game_server_pid)

		display_status(status) # Print game state
    player_action(:robot, {:game_start, secret_length}, state)
    { :next_state, :guessing_robot, state }

  end


  # 2) keep guessing, last letter correct
  def guessing_robot({:game_keep_guessing, :correct_letter}, state) do

    display_status(:game_keep_guessing, state) # Print game state
    player_action(:robot, {:correct_letter, state.last_guess, state.current_pattern}, state)
    { :next_state, :guessing_robot, state }

  end

  # 3) keep guessing, last letter incorrect
  def guessing_robot({:game_keep_guessing, :incorrect_letter}, state) do

    display_status(:game_keep_guessing, state) # Print game state
    player_action(:robot, {:incorrect_letter, state.last_guess, state.current_pattern}, state)
    { :next_state, :guessing_robot, state }

  end

  # 4) game won
  def guessing_robot({:game_won, _}, state) do
    
    display_status(:game_won, state) # Print game state
    robot_guess(self(), :game_start) # Queue up the next event 
    { :next_state, :guessing_robot, state }

  end

  # 5) game lost
  def guessing_robot({:game_lost, _}, state) do
    
    display_status(:game_lost, state) # Print game state
    robot_guess(self(), :game_start) # Queue up the next event 
    { :next_state, :guessing_robot, state }

  end

  # 6) game over
  def guessing_robot(:game_over, state) do
    
    display_status(:game_over, state) # Print game state
    robot_guess(self(), :game_reset)     # Queue up the next event 
    { :next_state, :guessing_robot, state }

  end

  # Helpers
	def display_status(text) when is_binary(text) do
  	IO.puts "#{text}\n"  	
  end

  def display_status(:game_over, state) do
  	IO.puts "#{inspect state.result}\n"  	
  end

  def display_status(_, state) do
  	IO.puts "#{inspect state.current_status_text}\n"  	
  end

  def player_action(:robot, current_pass_context, state) do
  
  	player = state.player_name
  	strategy = state.strategy

  	# Generate the word filter options for the word engine filter
		options = Strategy.word_filter_options(strategy, current_pass_context)

		# Filter the engine word set
		new_word_pass_state = WordEngine.filter_words(player, options)

		# Update the strategy with the result of the new pass state from the word engine
		strategy = Strategy.word_pass_update(strategy, new_word_pass_state)
    
    case Strategy.make_guess(strategy) do

      {:guess_word, guess_word} ->

      	guess = guess_word

        {{^player, guess_result, game_status, pattern, text}, final} =
          GameServer.guess_word(state.game_server_pid, guess_word)

      {:guess_letter, guess_letter} ->

      	guess = guess_letter

        {{^player, guess_result, game_status, pattern, text}, final} =
          GameServer.guess_letter(state.game_server_pid, guess_letter)
    
    end

    # TODO: Update to use GamePlay struct in addition to %State
    state = %State{ state | 
    	last_guess: state.current_guess,
      current_guess: guess,
      current_guess_result: guess_result, 
      current_game_status: game_status, 
      current_pattern: pattern, 
      current_status_text: text,
      final_result: final
		}

    # Queue up the next event 
    robot_guess(self(), {game_status, guess_result})
    
    # Queue up the next next event, if game_over
    case final do 
    	[] -> Nil
    	_ -> 
    		if Keyword.fetch!(final, :status) == :game_over do
    			robot_guess(self(), :game_over) 
 				end
    end

    Nil
  end

  def player_action(:human, decision_params, state) do
  	
  end


  # Since Elixir no longer supports GenFSM, we need to use
  # the Erlang module :gen_fsm as a behaviour and implement
  # the following functions below


  def handle_event(_event, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_sync_event(_event, _from, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_info(:stop, _state_name, state) do
    {:stop, :normal, state};
  end

  def handle_info(_Info, state_name, state) do
    {:next_state, state_name, state}
  end

  def code_change(_OldVsn, state_name, state, _extra) do
    {:ok, state_name, state}
  end

  def terminate(reason, _state_name, _state) do
    reason
  end

end