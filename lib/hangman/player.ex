defmodule Hangman.Player do
  @behaviour :gen_fsm

	alias Hangman.{Game, Reduction, Strategy, 
		Strategy.Options, Types.Game.Round}

  defmodule State do
    defstruct player_name: "", 
      game_server_pid: Nil, 
      seq_no: 0,
      mystery_letter: Game.Server.mystery_letter,
      strategy: Strategy.new,
      round: %Round{},
      final_result: ""
  end

  # External API
  def start_link(player_name, game_server_pid) do
    :gen_fsm.start_link(__MODULE__, {player_name, game_server_pid}, [])
  end

  # Events


  # Asynchronous Events

  # start
  def robot_guess(player_pid, event = :game_start) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 6) game_over
  def robot_guess(player_pid, event = :game_over) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 7) game_reset
  def robot_guess(player_pid, event = :game_reset) do
    :gen_fsm.send_event(player_pid, event)
  end

  # Synchronous Events

  # 0) status
  def robot_guess_sync(player_pid, event = :game_status) do
  	:gen_fsm.sync_send_event(player_pid, event)
  end  

  # 1) start guessing
  def robot_guess_sync(player_pid, event = :game_start) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 2) keep guessing, last letter correct
  def robot_guess_sync(player_pid, event = {:game_keep_guessing, :correct_letter}) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 3) keep guessing, last letter incorrect
  def robot_guess_sync(player_pid, event = {:game_keep_guessing, :incorrect_letter}) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 4) game won
  def robot_guess_sync(player_pid, event = {:game_won, _guess_result}) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 5) game lost
  def robot_guess_sync(player_pid, event = {:game_lost, _guess_result}) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 6) game_over
  def robot_guess_sync(player_pid, event = :game_over) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 7) game_reset
  def robot_guess_sync(player_pid, event = :game_reset) do
    :gen_fsm.sync_send_event(player_pid, event)
  end


  # State implementation helpers

  def gr_start(:game_start, state) do

    player = state.player_name

    {^player, :secret_length, secret_length} =
      Game.Server.secret_length(state.game_server_pid)

    {^player, :game_keep_guessing, _status} = 
			Game.Server.game_status(state.game_server_pid)

    player_action(:robot, {:game_start, secret_length}, state)
  end


  # Callbacks

  def init({player_name, game_server_pid}) do
    state = %State{player_name: player_name, 
    								game_server_pid: game_server_pid}

    #robot_guess(self(), :game_start)
    { :ok, :guessing_robot_state, state }
  end

  # GUESSING_ROBOT state

  # Asynchronous State Callbacks

  # 0) reset, asynchronous
  def guessing_robot_state(:game_reset, state) do 
  	_reply = display_status("GAME RESET STATE")

  	{ :next_state, :guessing_robot_state, state }
  end

  # 1) start, asynchronous
  def guessing_robot_state(:game_start, state) do
  	state = gr_start(:game_start, state)
  	robot_guess(self(), {state.round.status_code, state.round.result})

  	{ :next_state, :guessing_robot_state, state }
  end

  # 6) game over, asynchronous
  def guessing_robot_state(:game_over, state) do
    reply = display_status(:game_over, state) # Print game state

    IO.puts "game_over: #{inspect reply}"

    robot_guess(self(), :game_reset)     # Queue up the next event 
    
    { :next_state, :guessing_robot_state, state }
  end

  # Synchronous State Callbacks

  # status
  # synchronous
  def guessing_robot_state(:game_status, _from, state) do
  	reply = display_status(Nil, state)
    
    { :reply, reply, :guessing_robot_state, state }
  end

  # 1) start
	# synchronous
  def guessing_robot_state(:game_start, _from, state) do
  	state = gr_start(:game_start, state)
    reply = display_status(:game_start, state)	

    { :reply, reply, :guessing_robot_state, state }
  end

  # 2) keep guessing, last letter correct
  def guessing_robot_state({:game_keep_guessing, :correct_letter}, _from, state) do
    state = player_action(:robot, 
    	{:correct_letter, state.round.guess, state.round.pattern, state.mystery_letter}, state)
    reply = display_status(:game_keep_guessing, state) # Print game state

    { :reply, reply, :guessing_robot_state, state }
  end

  # 3) keep guessing, last letter incorrect
  def guessing_robot_state({:game_keep_guessing, :incorrect_letter}, _from, state) do
    state = player_action(:robot, {:incorrect_letter, state.round.guess}, state)
    reply = display_status(:game_keep_guessing, state) # Print game state
    
    { :reply, reply, :guessing_robot_state, state }
  end

  # 4) game won
  def guessing_robot_state({:game_won, _}, _from, state) do
    reply = display_status(:game_won, state) # Print game state
    #robot_guess(self(), :game_start) # Queue up the next event 

    { :reply, reply, :guessing_robot_state, state }
  end

  # 5) game lost
  def guessing_robot_state({:game_lost, _}, _from, state) do   
    reply = display_status(:game_lost, state) # Print game state
    #robot_guess(self(), :game_start) # Queue up the next event 

    { :reply, reply, :guessing_robot_state, state }
  end

  # 6) game over, synchronous
  def guessing_robot_state(:game_over, _from, state) do
    reply = display_status(:game_over, state) # Print game state

    IO.puts "game_over: #{inspect reply}"
    
    robot_guess(self(), :game_reset)     # Queue up the next event 
    
    { :reply, reply, :guessing_robot_state, state }
  end


  # Helpers
	defp display_status(text) do
		retval = text
  	IO.puts "#{inspect retval}\n"
  	retval
  end

  defp display_status(:game_over, state) do
  	retval = state.final_result
  	IO.puts "#{inspect retval}\n"
  	retval
  end

  defp display_status(_, state) do
  	retval = state.round.status_text
  	IO.puts "#{inspect retval}\n"
  	retval
  end

  def player_action(:robot, action_context, state) do

  	player = state.player_name
  	strategy = state.strategy
  	seq_no =  state.seq_no + 1

  	options = Keyword.new([{:id, player}, {:seq_no, seq_no}])

  	# Generate the word filter options for the words reduction engine
		filter_options = Options.filter_options(strategy, action_context)

		options = Keyword.merge(options, filter_options)

		match_key = Kernel.elem(action_context, 0)

		# Filter the engine hangman word set
		{^seq_no, reduction_pass_info} = Reduction.Engine.Stub.reduce(match_key, options)

		# Update the round strategy with the result of the reduction pass info _from the engine
		strategy = Strategy.update(strategy, reduction_pass_info)
    
    round_info = 
	    case Strategy.make_guess(strategy) do
	      {:guess_word, guess_word} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_word(state.game_server_pid, guess_word)

	       	%Round{seq_no: seq_no,
      			guess: guess_word, result: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}        

	      {:guess_letter, guess_letter} ->

	        {{^player, result, code, pattern, text}, final} =
	          Game.Server.guess_letter(state.game_server_pid, guess_letter)

	        %Round{seq_no: seq_no,
      			guess: guess_letter, result: result, 
      			status_code: code, pattern: pattern, 
      			status_text: text, final_result: final}
	    end

	  state = Kernel.put_in(state.round, round_info)
	  state = Kernel.put_in(state.strategy, strategy)
	  state = Kernel.put_in(state.seq_no, seq_no)

	  IO.puts "round: #{inspect round_info}"
    
    # Queue up the next event 
    #robot_guess(self(), {state.round.status_code, state.round.result})
    
    # Queue up the next next event, if game_over
    if round_info.final_result != "" and round_info.final_result != [] do
    	state = Kernel.put_in(state.final_result, round_info.final_result)
    
  		if Keyword.fetch!(round_info.final_result, :status) == :game_over do
  			#robot_guess(self(), :game_over)
			end
    end

    state
  end

  # TODO: Allow interactive game play along with robot determined guesses :)
  def player_action(:human, _action_context, _state) do
  	
  end

  # Since Elixir no longer supports GenFSM, we need to use
  # the Erlang module :gen_fsm as a behaviour and implement
  # the following functions below

  def handle_event(_event, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_sync_event(_event, __from, state_name, state) do
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