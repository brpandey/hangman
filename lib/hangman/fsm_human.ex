defmodule Hangman.Player.Human do

  alias Hangman.{Player, Guess}

  @behaviour :gen_fsm
  @moduledoc false

  @human Player.human
  @code_to_state_map  %{:game_keep_guessing => :guess, 
                        :game_won => :single_game_over,
                        :game_lost => :single_game_over}

  # External API
  
  @doc """
  fsm start and link wrapper function
  """
  @spec start_link(pid, pid, String.t, :atom) :: tuple
  def start_link(event_server_pid, game_server_pid, 
                 player_name, player_type) do
    
    Logger.info "Starting Hangman Player FSM Server"
    
    :gen_fsm.start_link(__MODULE__, 
                        {event_server_pid, game_server_pid, 
                         player_name, player_type},
                        [])
  end

  @doc """
  Stops fsm server process
  """

  @spec stop(pid) :: :ok
  def stop(fsm_pid) do
    :gen_fsm.send_all_state_event(fsm_pid, :stop)
  end


  # HUMAN PLAYER EVENTS - (synchronous)

  @doc """
  Sends next state transition.  
  Assumption is we are in a human state
  """

  @spec next(pid) :: term
  def next(fsm_pid) do
    :gen_fsm.sync_send_event(fsm_pid, :next)  
  end

  #
  #
  # STATES
  #
  #

  # OTP :gen_fsm Callbacks

  @doc """
  State machine initial callback routine

  Loads a new player abstraction and echo server, returns first game state
  """

  @callback init(tuple) :: {:ok, :atom, tuple}
  def init({event_pid, game_pid, player_name, type}) do

    player = Player.new(player_name, :human, game_pid, event_pid)

    #:sys.trace(echo_pid, true)    

    { :ok, :start, {player, echo_pid} }
  end


  #########################
  #                       #
  # socrates HUMAN states #
  #                       #
  #########################

  #
  # SYNCHRONOUS State Callbacks
  #


  @doc """
  Callback function for synchronous human state socrates and event :proceed
  """

  @callback idle_socrates(:atom, tuple, tuple) :: tuple
  def start(:next, _from, {player, pid}) do

    {player, reply} = Player.start(player)

    { :reply, reply, :guess, {player, pid} }
  end

  @doc """
  Callback function for synchronous human state choosing
  """

  @callback guess(Guess.t, tuple, tuple) :: tuple
  def guess(:next, _from, {player, pid}) do

    {player, reply} = Player.guess(player)
    
    next = Map.get(code_to_state_map, status_code)
    
    { :reply, reply, next, {player, pid} }
  end

  def single_game_over(:next, _from, {player, pid}) do
    # Call for the server status so we know 
    # if we should transition to start or games_over

    reply = Player.server_status(player)    

  end

  def games_over(:next, _from, {player, pid}) do
    {:games_over, _} = reply = Player.status(player, :games_over)
    
    {:reply, reply, :idling, {player, pid}}
  end

  def games_exit(:next, _from, {player, pid}) do
        
  end

end
