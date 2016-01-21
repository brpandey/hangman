defmodule Hangman.Player.FSM do
  @behaviour :gen_fsm


  alias Hangman.{Player.Client, Player.Async.Echo}

  # External API
  def start_link(player_name, player_type, game_server_pid) do
    :gen_fsm.start_link(__MODULE__, {player_name, player_type, game_server_pid}, [])
  end

  def start(player_name, player_type, game_server_pid) do
    :gen_fsm.start(__MODULE__, {player_name, player_type, game_server_pid}, [])
  end

  def stop(fsm_pid) do
    :gen_fsm.send_all_state_event(fsm_pid, :stop)
  end

  # HUMAN PLAYER EVENTS - (synchronous)
  def jedi_proceed(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :proceed)  

  def jedi_guess(fsm_pid, letter) when is_binary(letter) do
  	:gen_fsm.sync_send_event(fsm_pid, {:guess_letter, letter})
  end

  def jedi_win(fsm_pid) do
    :gen_fsm.sync_send_event(fsm_pid, :guess_last_word)
  end

  # ROBOT PLAYER EVENTS (synchronous - robot guessing)
  def r2d2_proceed(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :proceed)
  
  def r2d2_guess(fsm_pid) do
    :gen_fsm.sync_send_event(fsm_pid, :game_keep_guessing)
  end

  # TURBO ROBOT PLAYER EVENTS (asynchronous - robot guessing)
  def turbo_r2d2_proceed(fsm_pid), do: async_proceed(fsm_pid)

  # EXTRA
  def async_proceed(fsm_pid), do:  :gen_fsm.send_event(fsm_pid, :proceed)

  def async_guess(fsm_pid) do
    :gen_fsm.send_event(fsm_pid, :game_keep_guessing)
  end

  def sync_status(fsm_pid) do 
    :gen_fsm.sync_send_all_state_event(fsm_pid, :game_status)
  end 

  #
  #
  # STATES
  #
  #

  # OTP :gen_fsm Callbacks

  def init({player_name, type, game_server_pid}) do

    client = Client.new(player_name, type, game_server_pid)
    #initial_state = Client.fun_type_alias(client, :star_wars)

    initial = 
      case client.type do
        :human -> :idle_jedi
        :robot -> :idle_r2d2
        _ -> raise "unknown player type"
      end

    {:ok, echo_pid} = Echo.start_link()
    
    :sys.trace(echo_pid, true)    

    { :ok, initial, {client, echo_pid} }
  end


  #####################
  #                   #
  # jedi HUMAN states #
  #                   #
  #####################

  #
  # SYNCHRONOUS State Callbacks
  #


  def idle_jedi(:proceed, _from, {client, pid}) do

    reply = fsm_start_or_over_check(client)

    case reply do
      {:game_start} ->  
        client = Client.start(client)
        reply = Client.list_choices(client)
        { :reply, reply, :eager_jedi, {client, pid} }

      {:game_over} ->
        true = Client.game_over?(client) # assert
        client = Client.server_pull_status(client)
        reply = Client.game_over_status(client)

        IO.puts "#{inspect reply}"
#        { :stop, :normal, {client, pid} }
        { :reply, reply, :idle_jedi, {client, pid}}


      _ -> 
        { :reply, reply, :idle_jedi, {client, pid}}
    end

  end

  def eager_jedi({:guess_letter, guess_letter}, _from, {client, pid}) do

    client = Client.guess_letter(client, guess_letter)
    {status_code, _text} = reply = Client.round_status(client)

    next = 
      case status_code do
        :game_keep_guessing -> :eager_jedi
        :game_won -> :idle_jedi
        :game_lost -> :idle_jedi
      end

    if next == :eager_jedi do
      client = Client.choose_letters(client)
      reply = Client.list_choices(client)
    end

    { :reply, reply, next, {client, pid} }  	
  end

  def eager_jedi(:guess_last_word, _from, {client, pid}) do

    client = Client.guess_last_word(client)
    {status_code, _text} = reply = Client.round_status(client)

    next = 
      case status_code do
        :game_keep_guessing -> :eager_jedi
        :game_won -> :idle_jedi
        :game_lost -> :idle_jedi
      end

    if next == :eager_jedi do
      client = Client.choose_letters(client)
      reply = Client.list_choices(client)
    end

    { :reply, reply, next, {client, pid} }    
  end


  #####################
  #                   #
  # r2d2 ROBOT states #
  #                   #
  #####################


  #
  # SYNCHRONOUS State Callbacks
  #

  # 1) proceed
  def idle_r2d2(:proceed, _from, {client, pid}) do

    case fsm_start_or_over_check(client) do
      {:game_start} -> 
      	client = Client.start(client)
        reply = Client.round_status(client)
        { :reply, reply, :eager_r2d2, {client, pid} }
      
      {:game_over} ->
        true = Client.game_over?(client) # assert
        reply = Client.game_over_status(client)

        IO.puts "#{inspect reply}"
        #{ :stop, :normal, {client, pid} }
        { :reply, reply, :idle_r2d2, {client, pid}}


      _ -> 
        { :reply, "Shouldn't be here", :idle_r2d2, {client, pid}}
    end
  end

  # 2) game_keep_guessing
  def eager_r2d2(:game_keep_guessing, _from, {client, pid}) do

    client = Client.robot_guess(client, Nil)
    {status_code, _} = reply = Client.round_status(client)
    
    next = 
      case status_code do
        :game_keep_guessing -> :eager_r2d2
        :game_won -> :idle_r2d2
        :game_lost -> :idle_r2d2
      end
      
    { :reply, reply, next, {client, pid} }
  end

  #
  # ASYNCHRONOUS State Callbacks
  #

  # 1) proceed
  def idle_r2d2(:proceed, {client, echo_pid}) do

    case fsm_start_or_over_check(client) do

      {:game_start} -> 
        client = Client.start(client)
        Echo.echo_guess(echo_pid, self()) # Setup the next async echo event

        { :next_state, :eager_r3d3, {client, echo_pid} }

      {:game_over} ->
        true = Client.game_over?(client) # assert

        IO.puts "Game Over - Terminating FSM"
        { :stop, :normal, {client, echo_pid} }

      _ -> 
        { :next_state, :idle_r2d2, {client, echo_pid}}
    end
  end

  # 2) game keep guessing - r2d2 is so fast, it changes into r3d3
  def eager_r3d3(:game_keep_guessing, {client, echo_pid}) do

    client = Client.robot_guess(client, Nil)
    {status_code, _}  = Client.round_status(client)

    next_state = 
      case status_code do
        :game_keep_guessing -> 
          # Setup the next async echo event
          Echo.echo_guess(echo_pid, self())
          :eager_r3d3

        :game_won -> 
          # Setup the next async echo event
          Echo.echo_proceed(echo_pid, self())
          :idle_r2d2

        :game_lost -> 
          # Setup the next async echo event
          Echo.echo_proceed(echo_pid, self())
          :idle_r2d2
      end

    { :next_state, next_state, {client, echo_pid} }
  end


  # STATE HELPER functions

  # defp fsm_print_status(text), do: IO.puts "#{text}\n"
  # defp fsm_print_status(text, value), do: IO.puts "#{text} #{inspect value}\n"

  # def fsm_debug_spawn(file_name, term) do
  #  path = "/home/brpandey/Workspace/elixir-hangman/tmp"
  #  spawn(fn ->
  #    "#{path}/#{file_name}"
  #    |> File.write!(:erlang.term_to_binary(term))
  #    end)
  # end

  defp fsm_start_or_over_check(%Client{} = client) do

    case Client.game_won_or_lost?(client) do
      
      true -> # Single game finished

        case Client.game_over?(client) do # All games over?
          
          # All games finished
          true -> {:game_over}

          # Still more games left
          false -> {:game_start}
        end

      false -> # Start guessing
        {:game_start}
    end
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