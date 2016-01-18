defmodule Hangman.Player.FSM do
  @behaviour :gen_fsm


  alias Hangman.{Player.Client, Player.Echo}

  # External API
  def start_link(player_name, player_type, game_server_pid) do
    :gen_fsm.start_link(__MODULE__, {player_name, player_type, game_server_pid}, [])
  end

  def start(player_name, player_type, game_server_pid) do
    :gen_fsm.start(__MODULE__, {player_name, player_type, game_server_pid}, [])
  end

  def stop(fsm_pid), do: event_stop(fsm_pid)

  #
  # EVENTS (External API)

  # HUMAN PLAYER EVENTS - (synchronous)

  def human_start(fsm_pid), do:  sync_start(fsm_pid)
  def human_status(fsm_pid), do:  sync_status(fsm_pid)

  def human_guess(fsm_pid, letter) when is_binary(letter) do
  	:gen_fsm.sync_send_event(fsm_pid, {:guess_letter, letter})
  end

  # GENERAL PLAYER EVENTS
  # 1) start, 2-3) guess, 4) won, 5) lost, 6) game_over, 7) reset

  # Asynchronous Events
  def event_start(fsm_pid), do: :gen_fsm.send_event(fsm_pid, :game_start)
  def event_guess(fsm_pid), do: :gen_fsm.send_event(fsm_pid, :game_keep_guessing)
  def event_won(fsm_pid), do: :gen_fsm.send_event(fsm_pid, :game_won)
  def event_lost(fsm_pid), do:  :gen_fsm.send_event(fsm_pid, :game_lost)
  def event_game_over(fsm_pid), do: :gen_fsm.send_event(fsm_pid, :game_over)
  def event_stop(fsm_pid), do: :gen_fsm.send_all_state_event(fsm_pid, :stop)

  # Synchronous Events
  def sync_start(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :game_start)
  def sync_guess(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :game_keep_guessing)
  def sync_won(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :game_won)
  def sync_lost(fsm_pid), do: :gen_fsm.sync_send_event(fsm_pid, :game_lost)
  def sync_game_over(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :game_over)

  def sync_status(fsm_pid) do 
    :gen_fsm.sync_send_all_state_event(fsm_pid, :game_status)
  end 

  #
  #
  # STATE
  #
  #

  # OTP :gen_fsm Callbacks

  def init({player_name, type, game_server_pid}) do

    client = Client.new(player_name, type, game_server_pid)

    initial_state = Client.fun_type_alias(client, :star_wars)

    {:ok, echo_pid} = Echo.start_link()

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
  def jedi(:game_start, _from, {client, pid}) do

  	client = Client.start(client)
    reply = Client.list_choices(client)

    { :reply, reply, :eager_jedi, {client, pid} }
  end

  def jedi(:game_over, _from, {client, pid}) do

    true = Client.game_over?(client) # assert

    client = Client.server_pull_status(client)

    reply = Client.game_over_status(client)

    fsm_state_text = "jedi:game_over:sync"

    fsm_print_status(fsm_state_text, reply)

    { :stop, :normal, {client, pid} }
  end

  def eager_jedi({:guess_letter, guess_letter}, _from, {client, pid}) do

    client = Client.guess_letter(client, guess_letter)
    {status_code, _text} = reply = Client.round_status(client)

    IO.puts("eager_jedi, reply is: #{inspect reply}")

    next = 
      case status_code do
        :game_keep_guessing -> :eager_jedi
        :game_won -> :cheery_jedi
        :game_lost -> :disgruntled_jedi
      end

    if next == :eager_jedi do
      client = Client.choose_letters(client)
      reply = Client.list_choices(client)
    end

    { :reply, reply, next, {client, pid} }  	
  end

  def cheery_jedi(:game_won, _from, {client, pid}) do

    reply = Client.round_status(client)

    { :reply, reply, :jedi, {client, pid} }
  end

  def disgruntled_jedi(:game_lost, _from, {client, pid}) do

    reply = Client.round_status(client)

    { :reply, reply, :jedi, {client, pid} }
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

    client = Client.start(client)

    fsm_state_text = "r2d2:game_start:async"
    
    fsm_async_next_round(client, echo_pid, fsm_state_text)

    { :next_state, :eager_turbo_r2d2, {client, echo_pid} }
  end

  # 6) game over, asynchronous
  def r2d2(:game_over, {client, pid}) do

    true = Client.game_over?(client) # assert

    client = Client.server_pull_status(client)

    {:game_reset, status} = Client.game_over_status(client) # assert

    fsm_state_text = "r2d2:game_over:async"  

    fsm_debug_spawn(fsm_state_text, status)
        
    { :stop, :normal, {client, pid} }
  end

  # 2 & 3) generic keep guessing
  def eager_turbo_r2d2(:game_keep_guessing, {client, echo_pid}) do

    client = Client.robot_guess(client, Nil)

    fsm_state_text = "eager_turbo_r2d2:game_keep_guessing:async:round#{client.round_no}" 

    {status_code, _}  = Client.round_status(client)

    next_state = 
      case status_code do
        :game_keep_guessing -> :eager_turbo_r2d2
        :game_won -> :cheery_turbo_r2d2
        :game_lost -> :disgruntled_turbo_r2d2
      end

    fsm_async_next_round(client, echo_pid, fsm_state_text)
      
    { :next_state, next_state, {client, echo_pid} }
  end

  # 4) game won, asynchronous
  def cheery_turbo_r2d2(:game_won, {client, echo_pid}) do

    fsm_state_text = "cheery_turbo_r2d2:game_won:async"

    fsm_async_game_over_check(client, echo_pid, fsm_state_text)

    { :next_state, :r2d2, {client, echo_pid} }
  end

  # 5) game lost, asynchronous
  def disgruntled_turbo_r2d2(:game_lost, {client, echo_pid}) do

    fsm_state_text = "disgruntled_turbo_r2d2:game_lost:async"

    fsm_async_game_over_check(client, echo_pid, fsm_state_text)

    { :next_state, :r2d2, {client, echo_pid} }
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
  def r2d2(:game_start, _from, {client, pid}) do

  	client = Client.start(client)
    
    fsm_state_text = "r2d2:game_start:sync"

    reply = Client.round_status(client)        
    
    fsm_print_status(fsm_state_text, reply)

    { :reply, reply, :eager_r2d2, {client, pid} }
  end

  # 6) game over, synchronous
  def r2d2(:game_over, _from, {client, pid}) do

    true = Client.game_over?(client) # assert

    client = Client.server_pull_status(client)

    reply = Client.game_over_status(client)

    fsm_state_text = "r2d2:game_over:sync"

    fsm_print_status(fsm_state_text, reply)

    { :stop, :normal, {client, pid} }
  end

  # 2 & 3) generic keep guessing
  def eager_r2d2(:game_keep_guessing, _from, {client, pid}) do

    client = Client.robot_guess(client, Nil)

    fsm_state_text = "eager_r2d2:game_keep_guessing:sync"

    {status_code, _} = reply = Client.round_status(client)
        
    fsm_print_status(fsm_state_text, reply)

    next = 
      case status_code do
        :game_keep_guessing -> :eager_r2d2
        :game_won -> :cheery_r2d2
        :game_lost -> :disgruntled_r2d2
      end
      
    { :reply, reply, next, {client, pid} }
  end

  # 4) game won
  def cheery_r2d2(:game_won, _from, {client, pid}) do

    fsm_state_text = "cheery_r2d2:game_won:sync"

    true = Client.game_won?(client)

    reply = fsm_sync_game_over_check(client, fsm_state_text)

    { :reply, reply, :r2d2, {client, pid} }
  end

  # 5) game lost
  def disgruntled_r2d2(:game_lost, _from, {client, pid}) do   

    fsm_state_text = "disgruntled_r2d2:game_lost:sync"

    true = Client.game_lost?(client)

    reply = fsm_sync_game_over_check(client, fsm_state_text)
      
    { :reply, reply, :r2d2, {client, pid} }
  end


  # STATE HELPER functions

  # defp fsm_print_status(text), do: IO.puts "#{text}\n"
  defp fsm_print_status(text, value), do: IO.puts "#{text} #{inspect value}\n"

  defp fsm_sync_game_over_check(%Client{} = client, fsm_text) do

    case Client.game_won_or_lost?(client) do
      
      # Single game finished
      true ->
        case Client.game_over?(client) do

          # All games finished
          true -> 
            reply = Client.game_over_status(client)
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

  defp fsm_async_next_round(%Client{} = client, echo_pid, fsm_text) do

    case Client.game_won_or_lost?(client) do
      
      true->
        case Client.game_won?(client) do
          true -> 
            fsm_debug_spawn(fsm_text, Client.round_status(client))

            # Won
            # Setup the next echo event
            Echo.echo_won(echo_pid, self())

          false -> # Lost

            fsm_debug_spawn(fsm_text, Client.round_status(client))

            # Setup the next echo event
            Echo.echo_lost(echo_pid, self())

        end

      false ->
        # Setup the next echo event
        Echo.echo_guess(echo_pid, self())
    end
  end

  defp fsm_async_game_over_check(%Client{} = client, echo_pid, fsm_text) do
    case Client.game_over?(client) do
      
      true->
        # Queue up game_over async event
        #robot_sync_guess(self(), :game_over) 
        fsm_debug_spawn(fsm_text, Client.game_over_status(client))

        Echo.echo_game_over(echo_pid, self())

      false ->
        # Queue up game_start async event
        #robot_sync_guess(self(), :game_start)
        fsm_debug_spawn(fsm_text, Client.round_status(client))

        Echo.echo_start(echo_pid, self())        
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
  # to require the Erlang module :gen_fsm as a behaviour and implement
  # the following functions below


  def handle_event(:stop, _state_name, state) do
    {:stop, :normal, state};
  end

  def handle_event(_event, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_sync_event(:status, _from, state_name, state = {client, _pid}) do

    reply = Client.status(client)

    IO.puts("in handle_event")

    {:reply, reply, state_name, state}
  end

  def handle_sync_event(_event, __from, state_name, state) do
    {:next_state, state_name, state}
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