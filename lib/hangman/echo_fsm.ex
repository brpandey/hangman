defmodule Hangman.Player.Async.Echo do
	@behaviour :gen_fsm

  @moduledoc """
  Module serves as an asynchronous echo server for
  the asynchronous robot fsm player type

  Allows the asynchronous robot fsm player to run a game 
  asynchronously without having to be wrapped in a 
  Stream.run, runs automatically itself
  """

	# External API

  @doc """
  gen fsm start_link wrapper function
  """
  
  @spec start_link :: {:ok, pid}
  def start_link do
    :gen_fsm.start_link(__MODULE__, [], [])
  end


  # FSM API

  @doc """
  public api method to send an echo in the form of a async guess
  call back to the Player.FSM
  """

  @spec echo_guess(pid, pid) :: {}
  def echo_guess(fsm_pid, other_pid) do
 	  :gen_fsm.send_event(fsm_pid, {:echo_guess, other_pid})
  end

  # FSM Callbacks

  @doc """
  gen fsm callback to initalize server process
  """

  @callback init(Keyword.t) :: {:atom, :atom, []}
  def init(_), do: { :ok, :echo, [] }


  # Asynchronous FSM Callbacks

  @doc """
  gen fsm callback for initial and only state echo
  handles :echo_guess event
  """

  @callback echo({:atom, pid}, []) :: {:atom, :atom, []}
  def echo({:echo_guess, other_pid}, state) do
  	Hangman.Player.FSM.async_guess(other_pid)
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
