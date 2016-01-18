defmodule Hangman.Player.Echo do
	@behaviour :gen_fsm

	# External API

  def start_link() do
    :gen_fsm.start_link(__MODULE__, [], [])
  end


  # FSM API

  def echo_start(fsm_pid, other_pid) do
 	  :gen_fsm.send_event(fsm_pid, {:echo_start, other_pid})
  end

  def echo_guess(fsm_pid, other_pid) do
 	  :gen_fsm.send_event(fsm_pid, {:echo_guess, other_pid})
  end

  def echo_won(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, {:echo_won, other_pid})
  end

  def echo_lost(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, {:echo_lost, other_pid})
  end

  def echo_game_over(fsm_pid, other_pid) do
  	:gen_fsm.send_event(fsm_pid, {:echo_game_over, other_pid})
  end

  # FSM Callbacks

  def init(_) do
    { :ok, :echo, [] }
  end

  # Asynchronous FSM Callbacks

  def echo({:echo_start, other_pid}, state) do
  	Hangman.Player.FSM.event_start(other_pid)
  	{:next_state, :echo, state}
  end

  def echo({:echo_guess, other_pid}, state) do
  	Hangman.Player.FSM.event_guess(other_pid)
  	{:next_state, :echo, state}
  end

  def echo({:echo_won, other_pid}, state) do
    Hangman.Player.FSM.event_won(other_pid)
    {:next_state, :echo, state}
  end

  def echo({:echo_lost, other_pid}, state) do
    Hangman.Player.FSM.event_lost(other_pid)
    {:next_state, :echo, state}
  end

  def echo({:echo_game_over, other_pid}, state) do
    Hangman.Player.FSM.event_game_over(other_pid)
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