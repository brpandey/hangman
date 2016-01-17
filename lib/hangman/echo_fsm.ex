defmodule Hangman.Player.Echo do
	@behaviour :gen_fsm


	# External API

  def start_link() do
    :gen_fsm.start_link(__MODULE__, [], [])
  end


  # FSM API

  def echo_game_keep_guessing_async(fsm_pid, other_pid) do
 	  :gen_fsm.send_event(fsm_pid, 
 	  	_event = {:echo, :robot_guess_async, :game_keep_guessing, other_pid})
  end

  def echo_game_won_async(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, 
  		_event = {:echo, :robot_guess_async, :game_won, other_pid})
  end

  def echo_game_lost_async(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, 
  		_event = {:echo, :robot_guess_async, :game_lost, other_pid})
  end

  def echo_game_over_async(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, 
  		_event = {:echo, :robot_guess_async, :game_over, other_pid})
  end

  def echo_game_reset_async(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, 
  		_event = {:echo, :robot_guess_async, :game_reset, other_pid})
  end

  # OTP Callback

  def init(_) do
    { :ok, :echo, %{}}
  end

  # Asynchronous FSM Callbacks

  def echo({:echo, :robot_guess_async, :game_keep_guessing, other_pid}, state) do
  	Hangman.Player.FSM.robot_guess_async(other_pid, :game_keep_guessing)

  	{:next_state, :echo, state}
  end

  def echo({:echo, :robot_guess_async, :game_won, other_pid}, state) do
    Hangman.Player.FSM.robot_guess_async(other_pid, :game_won)

    {:next_state, :echo, state}
  end

  def echo({:echo, :robot_guess_async, :game_lost, other_pid}, state) do
    Hangman.Player.FSM.robot_guess_async(other_pid, :game_lost)

    {:next_state, :echo, state}
  end

  def echo({:echo, :robot_guess_async, :game_over, other_pid}, state) do
    Hangman.Player.FSM.robot_guess_async(other_pid, :game_over)

    {:next_state, :echo, state}
  end

  def echo({:echo, :robot_guess_async, :game_reset, other_pid}, state) do
    Hangman.Player.FSM.robot_guess_async(other_pid, :game_reset)
  
    {:next_state, :echo, state}
  end



  # BOILERPLATE

  # Since Elixir no longer supports :gen_fsm through GenFSM, we need
  # to use the Erlang module :gen_fsm as a behaviour and implement
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