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

  def robot_keep_guessing_async(fsm_pid) do
    robot_guess_async(fsm_pid, :game_keep_guessing)
  end

  # 1) start guessing
  def robot_guess_async(fsm_pid, event = :game_start) do
    :gen_fsm.send_event(fsm_pid, event)
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
  	:gen_fsm.sync_send_all_state_event(fsm_pid, :game_status)
  end  

  # 1) start guessing
  def robot_guess_sync(fsm_pid, event = :game_start) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

  # 2 & 3) keep guessing, 
  def robot_guess_sync(fsm_pid, event = :game_keep_guessing) do
    :gen_fsm.sync_send_event(fsm_pid, event)
  end

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

    {:ok, echo_pid} = Player.Echo.start_link()

    :sys.trace(echo_pid, true)

    { :ok, initial_state, {client, echo_pid} }
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
  def jedi(:game_start, _from, {client, echo_pid}) do

  	client = Player.Client.start(:game_start, :human, client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :jedi, {client, echo_pid} }
  end

  def jedi(:choose_letters, _from, {client, echo_pid}) do
  	
    client = Player.Client.choose_letters(client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :jedi, {client, echo_pid} }
  end

  def jedi({:guess_letter, guess_letter}, _from, {client, echo_pid}) do

    client = Player.Client.guess_letter(client, guess_letter)
    reply = Player.Client.status(client)

  	status(:reply)

    { :reply, reply, :jedi, {client, echo_pid} }  	
  end

  # To faciliate CYBORG state
  
  def jedi({:game_keep_guessing, _}, _from, {client, echo_pid}) do
    
    client = Player.Client.choose_letters(client)
    reply = Player.Client.list_choices(client)

    { :reply, reply, :jedi, {client, echo_pid} }
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
  def r2d2(:game_start, {client, echo_pid}) do

    client = Player.Client.start(client)

    fsm_state = "r2d2:game_start:async"

    #IO.puts "client: #{inspect client}, echo_pid: #{inspect echo_pid}, fsm_state: #{fsm_state}"
    
    fsm_async_next_round(client, echo_pid, fsm_state)

    { :next_state, :eager_r2d2, {client, echo_pid} }
  end

  # 6) game over, asynchronous
  def r2d2(:game_over, {client, echo_pid}) do

    true = Player.Client.game_over?(client) # assert

    {:game_reset, status} = Player.Client.server_status(client) # assert

    fsm_state = "r2d2:game_over:async"  

    fsm_debug_spawn(fsm_state, status)

    Player.Echo.echo_game_reset_async(echo_pid, self())

    # Queue up the next event
    #robot_guess_async(self(), :game_reset)      

    
    { :next_state, :zen_r2d2, {client, echo_pid} }
  end

  # 2 & 3) generic keep guessing
  def eager_r2d2(:game_keep_guessing, {client, echo_pid}) do

    client = Player.Client.robot_guess(client, Nil)

    fsm_state = "eager_r2d2:game_keep_guessing:async:round#{client.round_no}" 

    {status_code, _}  = Player.Client.round_status(client)

    next_state = 
      case status_code do
        :game_keep_guessing -> :eager_r2d2
        :game_won -> :cheery_r2d2
        :game_lost -> :disgruntled_r2d2
      end

    fsm_async_next_round(client, echo_pid, fsm_state)
      
    { :next_state, next_state, {client, echo_pid} }
  end

  # 4) game won, asynchronous
  def cheery_r2d2(:game_won, {client, echo_pid}) do

    fsm_state = "cheery_r2d2:game_won:async"

    fsm_async_game_over_check(client, echo_pid, fsm_state)

    { :next_state, :r2d2, {client, echo_pid} }
  end

  # 5) game lost, asynchronous
  def disgruntled_r2d2(:game_lost, {client, echo_pid}) do

    fsm_state = "disgruntled_r2d2:game_lost:async"

    fsm_async_game_over_check(client, echo_pid, fsm_state)

    { :next_state, :r2d2, {client, echo_pid} }
  end


  # 7) reset, asynchronous
  def zen_r2d2(:game_reset, {client, echo_pid}) do 
    
    {:game_reset, status} = Player.Client.server_status(client)
    
    fsm_state = "zen_r2d2:game_reset:async"
    
    fsm_debug_spawn(fsm_state, status)

    stop(self())


    { :next_state, :zen_r2d2, {client, echo_pid} }
  end

  #####################
  #                   #
  # r2d2 ROBOT states #
  #                   #
  #####################

  #
  # SYNCHRONOUS State Callbacks
  #


  # 1) start
  def r2d2(:game_start, _from, {client, echo_pid}) do

  	client = Player.Client.start(client)
    
    fsm_state = "idle_r2d2:game_start:sync"

    reply = Player.Client.round_status(client)        
    
    fsm_print_status(fsm_state, reply)
      

    { :reply, reply, :eager_r2d2, {client, echo_pid} }
  end

  # 6) game over, synchronous
  def r2d2(:game_over, _from, {client, echo_pid}) do

    true = Player.Client.game_over?(client) # assert

    reply = Player.Client.server_status(client)  

    fsm_state = "idle_r2d2:game_over:sync"

    fsm_print_status(fsm_state, reply)

    { :reply, reply, :zen_r2d2, {client, echo_pid} }
  end

  # 2 & 3) generic keep guessing
  def eager_r2d2(:game_keep_guessing, _from, {client, echo_pid}) do

    client = Player.Client.robot_guess(client, Nil)

    fsm_state = "eager_r2d2:game_keep_guessing:sync"

    {status_code, _} = reply = Player.Client.round_status(client)
        
    fsm_print_status(fsm_state, reply)

    next_state = 
      case status_code do
        :game_keep_guessing -> :eager_r2d2
        :game_won -> :cheery_r2d2
        :game_lost -> :disgruntled_r2d2
      end
      
    { :reply, reply, next_state, {client, echo_pid} }
  end

  # 4) game won
  def cheery_r2d2(:game_won, _from, {client, echo_pid}) do

    fsm_state = "cheery_r2d2:game_won:sync"

    reply = fsm_sync_game_over_check(client, fsm_state)

    true = Player.Client.game_won?(client)

    reply = 
      case Player.Client.game_over?(client) do

        # All games finished
        true -> 
          reply = Player.Client.game_over_status(client)
          fsm_print_status(fsm_state, reply)
          reply
        
        # Still more games left
        false -> 
          {:game_start}
      end

    { :reply, reply, :r2d2, {client, echo_pid} }
  end

  # 5) game lost
  def disgruntled_r2d2(:game_lost, _from, {client, echo_pid}) do   

    fsm_state = "disgruntled_r2d2:game_lost:sync"

    reply = fsm_sync_game_over_check(client, fsm_state)

    true = Player.Client.game_lost?(client)

    reply = 
      case Player.Client.game_over?(client) do

        # All games finished
        true -> 
          reply = Player.Client.game_over_status(client)
          fsm_print_status(fsm_state, reply)
          reply
        
        # Still more games left
        false -> 
          {:game_start}
      end
      
    { :reply, reply, :r2d2, {client, echo_pid} }
  end


  # 7) reset, synchronous
  def zen_r2d2(:game_reset, _from, {client, echo_pid}) do 
    
    reply = Player.Client.status(client)
    
    fsm_state = "zen_r2d2:game_reset:sync"

    fsm_print_status(fsm_state, reply)

    { :reply, reply, :zen_r2d2, {client, echo_pid} }
  end


  # STATE HELPER functions

  # defp fsm_print_status(text), do: IO.puts "#{text}\n"
  defp fsm_print_status(text, value), do: IO.puts "#{text} #{inspect value}\n"

  defp fsm_sync_game_over_check(%Player.Client{} = client, fsm_text) do

    case Player.Client.game_won_or_lost?(client) do
      
      # Single game finished
      true ->
        case Player.Client.game_over?(client) do

          # All games finished
          true -> 
            reply = Player.Client.game_over_status(client)
            fsm_print_status(fsm_text, reply)
            reply
          
          # Still more games left
          false -> 
            {:game_start}
        end

      false -> 
        raise "Should not be here"
    end
  end

  defp fsm_async_next_round(%Player.Client{} = client, echo_pid, fsm_text) do

    case Player.Client.game_won_or_lost?(client) do
      
      true->
        case Player.Client.game_won?(client) do
          true -> 
            fsm_debug_spawn(fsm_text, Player.Client.round_status(client))

            # Won
            # Setup the next echo event
            Player.Echo.echo_game_won_async(echo_pid, self())

          false -> # Lost

            fsm_debug_spawn(fsm_text, Player.Client.round_status(client))

            # Setup the next echo event
            Player.Echo.echo_game_lost_async(echo_pid, self())

        end

      false ->
        # Setup the next echo event
        Player.Echo.echo_game_keep_guessing_async(echo_pid, self())
    end
  end

  defp fsm_async_game_over_check(%Player.Client{} = client, echo_pid, fsm_text) do
    case Player.Client.game_over?(client) do
      
      true->
        # Queue up game_over async event
        #robot_guess_sync(self(), :game_over) 
        fsm_debug_spawn(fsm_text, Player.Client.game_over_status(client))

        Player.Echo.echo_game_over_async(echo_pid, self())

      false ->
        # Queue up game_start async event
        #robot_guess_sync(self(), :game_start)
        fsm_debug_spawn(fsm_text, Player.Client.round_status(client))

        Player.Echo.echo_game_start_async(echo_pid, self())        
    end
  end

  def fsm_debug_spawn(file_name, term) do
    path = "/home/brpandey/Workspace/elixir-hangman/tmp"
    spawn(fn ->
      "#{path}/#{file_name}"
      |> File.write!(:erlang.term_to_binary(term))
      end)
  end

  # BOILERPLATE

  # Since Elixir no longer supports :gen_fsm through GenFSM, we need
  # to use the Erlang module :gen_fsm as a behaviour and implement
  # the following functions below


  def handle_event(:status, _from, state_name, state = {client, _}) do


    IO.puts("in handle_event")

    reply = Player.Client.status(client)
    {:reply, reply, state_name, state}
  end

  def handle_event(_event, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_sync_event(_event, __from, state_name, state) do

    IO.puts("in handle_sync_event")

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