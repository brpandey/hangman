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

  def stop(fsm_pid) do
		:gen_fsm.send_all_state_event(fsm_pid, :stop)
	end

  # PLAYER EVENTS
  #
  # HUMAN (synchronous)

  def human_start(fsm_pid) do
  	:gen_fsm.send_event(fsm_pid, :human)
  	:gen_fsm.sync_send_event(fsm_pid, :game_start)
  end

  def choose_letters(fsm_pid) do
  	:gen_fsm.sync_send_event(fsm_pid, :choose_letters)
  end

  def guess_letter(fsm_pid, letter) when is_binary(letter) do
  	:gen_fsm.sync_send_event(fsm_pid, {:guess_letter, letter})
  end

  def status(fsm_pid) do
    :gen_fsm.sync_send_event(fsm_pid, :choose_letters)
  end

  # PLAYER EVENTS
  #
  # ROBOT (Asynchronous Events)

  def robot_async_start(fsm_pid) do
    robot_guess_async(fsm_pid, :game_start) 
  end

  # 1) start guessing
  def robot_guess_async(fsm_pid, event = :game_start) do
    :gen_fsm.send_event(fsm_pid, event)
  end

  def robot_keep_guessing_async(fsm_pid) do
    robot_guess_async(fsm_pid, :game_keep_guessing)
  end

  # 2 & 3) keep guessing, 
  def robot_guess_async(fsm_pid, event = :game_keep_guessing) do
    :gen_fsm.send_event(fsm_pid, event)
  end


  # 4) game won
  def robot_guess_async(fsm_pid, event = :game_won) do
    :gen_fsm.send_event(fsm_pid, event)
  end

  # 5) game lost
  def robot_guess_async(fsm_pid, event = :game_lost) do
    :gen_fsm.send_event(fsm_pid, event)
  end

  # 6) game_over
  def robot_guess_async(fsm_pid, event = :game_over) do
    :gen_fsm.send_event(fsm_pid, event)
  end

  # 7) game_reset
  def robot_guess_async(fsm_pid, event = :game_reset) do
    :gen_fsm.send_event(fsm_pid, event)
  end

  # PLAYER EVENTS
  #
  # ROBOT (Synchronous Events)

  def robot_sync_start(fsm_pid) do
    robot_guess_sync(fsm_pid, :game_start) 
  end

  def robot_keep_guessing(fsm_pid) do
    robot_guess_sync(fsm_pid, :game_keep_guessing)
  end

  # 0) status

  def robot_status(fsm_pid) do
    robot_guess_sync(fsm_pid, :game_status)
  end

  def robot_guess_sync(fsm_pid, event = :game_status) do
  	:gen_fsm.sync_send_event(fsm_pid, event)
  end  

  # 1) start guessing
  def robot_guess_sync(fsm_pid, event = :game_start) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  # 2 & 3) keep guessing, 
  def robot_guess_sync(fsm_pid, event = :game_keep_guessing) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

_ = """ 
DEPRECATED
  # 2) keep guessing, last letter correct
  def robot_guess_sync(fsm_pid, event = {:game_keep_guessing, :correct_letter, context}) do

    {:correct_letter, _last_guess, _current_pattern, _mystery_letter} = context # Assert

    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  # 3) keep guessing, last letter incorrect
  def robot_guess_sync(fsm_pid, event = {:game_keep_guessing, :incorrect_letter, _letter}) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end
"""

  # 4) game won
  def robot_guess_sync(fsm_pid, event = :game_won) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  # 5) game lost
  def robot_guess_sync(fsm_pid, event = :game_lost) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  # 6) game_over
  def robot_guess_sync(fsm_pid, event = :game_over) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  # 7) game_reset
  def robot_guess_sync(fsm_pid, event = :game_reset) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  #
  #
  # STATE
  #
  #

  # OTP :gen_fsm Callbacks

  def init({player_name, type, game_server_pid}) do

    client = Player.Client.new(player_name, type, game_server_pid)

    initial_state = Player.Client.fun_type_alias(client, :star_wars)

    { :ok, initial_state, client }
  end


  #####################
  #                   #
  # jedi HUMAN states #
  #                   #
  #####################

  #
  # SYNCHRONOUS State Callbacks
  #

  # 1) start
  def jedi(:game_start, _from, client) do

  	client = Player.Client.start(:game_start, :human, client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :jedi, client }
  end

  def jedi(:choose_letters, _from, client) do
  	
    client = Player.Client.choose_letters(client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :jedi, client }
  end

  def jedi({:guess_letter, guess_letter}, _from, client) do

    client = Player.Client.guess_letter(client, guess_letter)
    reply = Player.Client.status(client)

  	status(:reply)

    { :reply, reply, :jedi, client }  	
  end

  # To faciliate CYBORG state
  
  def jedi({:game_keep_guessing, _}, _from, client) do
    
    client = Player.Client.choose_letters(client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :jedi, client }
  end
  

  #####################
  #                   #
  # r2d2 ROBOT states #
  #                   #
  #####################

  #
  # ASYNCHRONOUS State Callbacks
  #



  # 1) start
  def r2d2(:game_start, client) do

    client = Player.Client.start(client)
    reply = Player.Client.status(client)

    # Quickly queue up game_start async event
    robot_guess_async(self(), :game_keep_guessing) 

    { :next_state, :r2d2, client }
  end

  # 2 & 3) generic keep guessing
  def r2d2(:game_keep_guessing, client) do

    client = Player.Client.robot_guess(client, Nil)

    fsm_state = "r2d2:game_keep_guessing:async"
    fsm_async_game_won_or_lost?(client, fsm_state)
    
    { :next_state, :r2d2, client }
  end

  # 4) game won, asynchronous
  def r2d2(:game_won, client) do

    fsm_state = "r2d2:game_won:async"
    fsm_async_game_over?(client, fsm_state)

    { :next_state, :r2d2, client }
  end

  # 5) game lost, asynchronous
  def r2d2(:game_lost, client) do

    fsm_state = "r2d2:game_lost:async"
    fsm_async_game_over?(client, fsm_state)

    { :next_state, :r2d2, client }
  end


  # 6) game over, asynchronous
  def r2d2(:game_over, client) do

    true = Player.Client.game_over?(client) # assert

    # TODO change to Player.Client.server_status
    reply = Player.Client.status(client)

    fsm_state = "r2d2:game_over:async"  

    # Queue up the next event
    robot_guess_async(self(), :game_reset)      
    
    { :next_state, :r2d2, client }
  end

  # 7) reset, asynchronous
  def r2d2(:game_reset, client) do 
    
    # TODO: Should be like server_status
    reply = Player.Client.status(client)
    
    fsm_state = "r2d2:game_reset:async"

    { :next_state, :r2d2, client }
  end

  #####################
  #                   #
  # r2d2 ROBOT states #
  #                   #
  #####################

  #
  # SYNCHRONOUS State Callbacks
  #

  # 0) status
  def r2d2(:game_status, _from, client) do

  	reply = Player.Client.status(client)
    
    { :reply, reply, :r2d2, client }
  end

  # 1) start
  def r2d2(:game_start, _from, client) do

  	client = Player.Client.start(client)
    reply = Player.Client.status(client)

    fsm_state = "r2d2:game_start:sync"
    fsm_print_status(fsm_state, reply)

    { :reply, {:game_start, fsm_state, reply}, :r2d2, client }
  end

  # 2 & 3) generic keep guessing
  def r2d2(:game_keep_guessing, _from, client) do

    client = Player.Client.robot_guess(client, Nil)

    fsm_state = "r2d2:game_keep_guessing:sync"
    reply = fsm_sync_game_won_or_lost?(client, fsm_state)
    
    { :reply, reply, :r2d2, client }
  end

  # 4) game won
  def r2d2(:game_won, _from, client) do

    fsm_state = "r2d2:game_won:sync"
    reply = fsm_sync_game_over?(client, fsm_state)

    { :reply, reply, :r2d2, client }
  end

  # 5) game lost
  def r2d2(:game_lost, _from, client) do   

    fsm_state = "r2d2:game_lost:sync"
    reply = fsm_sync_game_over?(client, fsm_state)
    
    { :reply, reply, :r2d2, client }
  end

  # 6) game over, synchronous
  def r2d2(:game_over, _from, client) do

    true = Player.Client.game_over?(client) # assert

    # TODO: Should be server status
    reply = Player.Client.status(client)  

    fsm_state = "r2d2:game_over:sync"
    fsm_print_status(fsm_state, reply)

    { :reply, {:game_reset, fsm_state, reply}, :r2d2, client }
  end

  # 7) reset, synchronous
  def r2d2(:game_reset, _from, client) do 
    
    # TODO: Should be like server_status
    reply = Player.Client.status(client)
    
    fsm_state = "r2d2:game_reset:sync"
    fsm_print_status(fsm_state, reply)

    { :reply, {:game_reset, fsm_state, reply}, :r2d2, client }
  end


  # STATE HELPER functions

  defp fsm_print_status(text), do: IO.puts "#{text}\n"
  defp fsm_print_status(text, value), do: IO.puts "#{text} #{inspect value}\n"

  defp fsm_sync_game_won_or_lost?(%Player.Client{} = client, fsm_text) do
    
    status = Player.Client.round_status(client)
    fsm_print_status(fsm_text, status)

    case Player.Client.game_won_or_lost?(client) do
      true -> 
        case Player.Client.game_won?(client) do
          true ->  {:game_won, fsm_text, status}
          false -> {:game_lost, fsm_text, status}
        end
      false ->
        {:game_keep_guessing, fsm_text, status}
    end
  end

  defp fsm_async_game_won_or_lost?(%Player.Client{} = client, _fsm_text) do

    case Player.Client.game_won_or_lost?(client) do
      true->

        case Player.Client.game_won?(client) do
          true -> # Won
            # Quickly queue up game_won async event
            robot_guess_async(self(), :game_won)
          false -> # Lost
            # Quickly queue up game_lost async event
            robot_guess_async(self(), :game_lost)
        end

      false ->

        # Quickly queue up game_start async event
        robot_guess_async(self(), :game_keep_guessing) 

    end
  end

  defp fsm_sync_game_over?(%Player.Client{} = client, fsm_text) do

    reply = Player.Client.round_status(client)

    case Player.Client.game_won_or_lost?(client) do
      true ->

        case Player.Client.game_over?(client) do
          true -> 
            reply = Player.Client.status(client)
            fsm_print_status(fsm_text, reply)
            {:game_over, fsm_text, reply}
          
          false -> 
            fsm_print_status(fsm_text, reply)    
            {:game_start, fsm_text, reply}
        end

      false -> 
        fsm_print_status(fsm_text, reply)
        {:game_keep_guessing, fsm_text, reply}
    end

  end

  defp fsm_async_game_over?(%Player.Client{} = client, _fsm_text) do
    case Player.Client.game_over?(client) do
      true->
        "game over"
        # Queue up game_over async event
        #robot_guess_sync(self(), :game_over) 

      false ->
        ""
        # Queue up game_start async event
        #robot_guess_sync(self(), :game_start) 
    end
  end

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