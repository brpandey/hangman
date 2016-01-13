defmodule Hangman.Player.FSM do
  @behaviour :gen_fsm

  alias Hangman.{Player}

  # External API
  def start_link(player_name, player_type, game_server_pid) do
    :gen_fsm.start_link(__MODULE__, {player_name, player_type, game_server_pid}, [])
  end


  #
  #
  # EVENTS (External API)
  #
  #

  def stop(player_pid) do
		:gen_fsm.send_all_state_event(player_pid, :stop)
	end

  # PLAYER EVENTS

  # HUMAN (synchronous)

  def human_start(player_pid) do
  	:gen_fsm.send_event(player_pid, :human)
  	:gen_fsm.sync_send_event(player_pid, :game_start)
  end

  def choose_letters(player_pid) do
  	:gen_fsm.sync_send_event(player_pid, :choose_letters)
  end

  def guess_letter(player_pid, letter) when is_binary(letter) do
  	:gen_fsm.sync_send_event(player_pid, {:guess_letter, letter})
  end

  def status(player_pid) do
    :gen_fsm.sync_send_event(player_pid, :choose_letters)
  end

  # ROBOT (Asynchronous Events)

  # 6) game_over
  def robot_guess_async(player_pid, event = :game_over) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 7) game_reset
  def robot_guess_async(player_pid, event = :game_reset) do
    :gen_fsm.send_event(player_pid, event)
  end

  # ROBOT (Synchronous Events)

  def robot_start(player_pid) do
    robot_guess_sync(player_pid, :game_start) 
  end

  def robot_keep_guessing(player_pid) do
    robot_guess_sync(player_pid, _event = :game_keep_guessing)
  end

  # 0) status
  def robot_guess_sync(player_pid, event = :game_status) do
  	:gen_fsm.sync_send_event(player_pid, event)
  end  

  # 1) start guessing
  def robot_guess_sync(player_pid, event = :game_start) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 2) keep guessing, last letter correct
  def robot_guess_sync(player_pid, event = :game_keep_guessing) do
    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 2) keep guessing, last letter correct
  def robot_guess_sync(player_pid, event = {:game_keep_guessing, :correct_letter, context}) do

    {:correct_letter, _last_guess, _current_pattern, _mystery_letter} = context # Assert

    :gen_fsm.sync_send_event(player_pid, event)
  end

  # 3) keep guessing, last letter incorrect
  def robot_guess_sync(player_pid, event = {:game_keep_guessing, :incorrect_letter, _letter}) do
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

  #
  #
  # STATE
  #
  #

  # OTP :gen_fsm Callbacks

  def init({player_name, type, game_server_pid}) do

    client = Player.Client.new(player_name, type, game_server_pid)

    initial_state = Player.Client.type_alias(client, :star_wars)

    { :ok, initial_state, client }
  end

  # GUESSING_HUMAN state

  # 1) start
	# synchronous
  def luke_skywalker(:game_start, _from, client) do

  	client = Player.Client.start(:game_start, :human, client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :luke_skywalker, client }
  end

  def luke_skywalker(:choose_letters, _from, client) do
  	
    client = Player.Client.choose_letters(client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :luke_skywalker, client }
  end

  def luke_skywalker({:guess_letter, guess_letter}, _from, client) do

    client = Player.Client.guess_letter(client, guess_letter)
    reply = Player.Client.status(client)

  	status(:reply)

    { :reply, reply, :luke_skywalker, client }  	
  end

  # To faciliate CYBORG state
  
  def luke_skywalker({:game_keep_guessing, _}, _from, client) do
    
    client = Player.Client.choose_letters(client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :luke_skywalker, client }
  end
  

  # GUESSING_ROBOT state

  # Asynchronous State Callbacks

  # 0) reset, asynchronous
  def c3po(:game_reset, client) do 
  	
    reply = Player.Client.status(client)
    
    fsm_status(reply)

  	{ :next_state, :c3po, client }
  end

  # 6) game over, asynchronous
  def c3po(:game_over, client) do
    
    reply = Player.Client.status(client)
    
    fsm_status(reply)

    robot_guess_async(self(), :game_reset)     # Queue up the next event 
    
    { :next_state, :c3po, client }
  end

  # Synchronous State Callbacks

  # status
  # synchronous
  def c3po(:game_status, _from, client) do

  	reply = Player.Client.status(client)
    
    { :reply, reply, :c3po, client }
  end

  # 1) start
	# synchronous
  def c3po(:game_start, _from, client) do

  	client = Player.Client.start(client)
    
    reply = Player.Client.status(client)
    
    fsm_status(reply)

    { :reply, reply, :c3po, client }
  end

  def c3po(:game_keep_guessing, _from, client) do

    client = Player.Client.robot_guess(client, Nil)

    reply = Player.Client.status(client)
    
    fsm_status(reply) 
    
    { :reply, reply, :c3po, client }
  end

  # 2) keep guessing, last letter correct
  def c3po({:game_keep_guessing, :correct_letter, context}, _from, client) do

    client = Player.Client.robot_guess(client, context)

    reply = Player.Client.status(client)

    fsm_status(reply) 

    { :reply, reply, :c3po, client }
  end

    # 3) keep guessing, last letter incorrect
  def c3po({:game_keep_guessing, :incorrect_letter, 
                              incorrect_letter}, _from, client) do

    client = Player.Client.robot_guess(client, 
                    {:incorrect_letter, incorrect_letter})

    reply = Player.Client.status(client)
    
    fsm_status(reply) 
    
    { :reply, reply, :c3po, client }
  end

  # 4) game won
  def c3po({:game_won, _}, _from, client) do

    reply = Player.Client.status(client)
    
    fsm_status(reply) 

    #robot_guess(self(), :game_start) # Queue up the next event 

    { :reply, reply, :c3po, client }
  end

  # 5) game lost
  def c3po({:game_lost, _}, _from, client) do   

    reply = Player.Client.status(client)
    
    fsm_status(reply) 

    #robot_guess(self(), :game_start) # Queue up the next event 

    { :reply, reply, :c3po, client }
  end

  # 6) game over, synchronous
  def c3po(:game_over, _from, client) do

    reply = Player.Client.status(client)
    
    fsm_status(reply)

    #robot_guess(self(), :game_start) # Queue up the next event 
    
    robot_guess_async(self(), :game_reset)     # Queue up the next event 
    
    { :reply, reply, :c3po, client }
  end

  defp fsm_status(text), do: IO.puts "#{inspect text}\n"

  # BOILERPLATE

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