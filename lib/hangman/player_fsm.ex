defmodule Hangman.Player.FSM do
  @behaviour :gen_fsm

  alias Hangman.{Player, Player.Async.Echo}

  # External API
  def start_link(player_name, player_type, game_server_pid, event_server_pid) do
    IO.puts "Starting Hangman FSM Server"

    :gen_fsm.start_link(__MODULE__, {player_name, player_type, 
      game_server_pid, event_server_pid}, [])
  end

  def start(player_name, player_type, game_server_pid, event_server_pid) do
    IO.puts "Starting Hangman FSM Server"

    :gen_fsm.start(__MODULE__, {player_name, player_type, 
      game_server_pid, event_server_pid}, [])
  end

  def stop(fsm_pid) do
    :gen_fsm.send_all_state_event(fsm_pid, :stop)
  end

  # HUMAN PLAYER EVENTS - (synchronous)
  def socrates_proceed(fsm_pid), do:  :gen_fsm.sync_send_event(fsm_pid, :proceed)  

  def socrates_guess(fsm_pid, letter) when is_binary(letter) do
  	:gen_fsm.sync_send_event(fsm_pid, {:guess_letter, letter})
  end

  def socrates_win(fsm_pid) do
    :gen_fsm.sync_send_event(fsm_pid, :guess_last_word)
  end

  # ROBOT PLAYER EVENTS (synchronous - robot guessing)  
  def wall_e_guess(fsm_pid) do
    :gen_fsm.sync_send_event(fsm_pid, :game_keep_guessing)
  end

  # TURBO ROBOT PLAYER EVENTS (asynchronous - robot guessing)
  def turbo_wall_e_guess(fsm_pid) do 
    :gen_fsm.send_event(fsm_pid, :game_keep_guessing)
  end

  def async_guess(fsm_pid) do 
    :gen_fsm.send_event(fsm_pid, :game_keep_guessing)
  end  


  # STATUS -- EXTRA
  def sync_status(fsm_pid) do 
    :gen_fsm.sync_send_all_state_event(fsm_pid, :game_status)
  end 

  def sync_game_over_status(fsm_pid) do 
    :gen_fsm.sync_send_all_state_event(fsm_pid, :game_over_status)
  end 

  #
  #
  # STATES
  #
  #

  # OTP :gen_fsm Callbacks

  def init({player_name, type, game_server_pid, event_server_pid}) do

    player = Player.new(player_name, type, game_server_pid, event_server_pid)

    initial = 
      case player.type do
        :human -> :idle_socrates
        :robot -> :neutral_wall_e
        _ -> raise "unknown player type"
      end

    {:ok, echo_pid} = Echo.start_link()
    
    #:sys.trace(echo_pid, true)    

    { :ok, initial, {player, echo_pid} }
  end


  #########################
  #                       #
  # socrates HUMAN states #
  #                       #
  #########################

  #
  # SYNCHRONOUS State Callbacks
  #

  # Since human will be calling, want to guard for events unsupported 
  # in current states, rather than crashing

  def idle_socrates({:guess_letter, _guess_letter}, _from, {player, pid}) do
    { :reply, "Event unsupported in given state", :idle_socrates, {player, pid} } 
  end

  def idle_socrates(:guess_last_word, _from, {player, pid}) do
    { :reply, "Event unsupported in given state", :idle_socrates, {player, pid} } 
  end  

  def idle_socrates(:proceed, _from, {player, pid}) do

    reply = game_start_or_over_check(player)

    case reply do
      {:game_start} ->  
        player = Player.start(player)
        reply = Player.list_choices(player)

        { :reply, reply, :eager_socrates, {player, pid} }

      {:game_over} ->
        {:game_over, reply} = Player.game_over_status(player)

        { :reply, reply, :idle_socrates, {player, pid}}

      _ -> 
        { :reply, reply, :idle_socrates, {player, pid}}
    end

  end

  def eager_socrates(:proceed, _from, {player, pid}) do
    { :reply, "Event unsupported in given state", :eager_socrates, {player, pid} } 
  end

  def eager_socrates(:guess_last_word, _from, {player, pid}) do
    { :reply, "Event unsupported in given state", :eager_socrates, {player, pid} } 
  end

  def eager_socrates({:guess_letter, guess_letter}, _from, {player, pid}) do

    player = Player.guess_letter(player, guess_letter)
    {status_code, reply} = Player.round_status(player)

    next = 
      case status_code do
        :game_keep_guessing -> :eager_socrates
        :game_won -> :idle_socrates
        :game_lost -> :idle_socrates
      end

    if next == :eager_socrates do
      player = Player.choose_letters(player)
      reply = Player.list_choices(player)

      if Player.last_word?(player), do: next = :giddy_socrates
    end

    { :reply, reply, next, {player, pid} }  	
  end

  def giddy_socrates(:proceed, _from, {player, pid}) do
    { :reply, "Event unsupported in given state", :giddy_socrates, {player, pid} } 
  end 

  def giddy_socrates({:guess_letter, _guess_letter}, _from, {player, pid}) do
    { :reply, "Event unsupported in given state", :giddy_socrates, {player, pid} } 
  end

  def giddy_socrates(:guess_last_word, _from, {player, pid}) do

    player = Player.guess_last_word(player)
    {status_code, reply} = Player.round_status(player)

    next = 
      case status_code do
        :game_keep_guessing -> :eager_socrates
        :game_won -> :idle_socrates
        :game_lost -> :idle_socrates
      end

    if next == :eager_socrates do
      raise "Shouldn't be here"
    end

    { :reply, reply, next, {player, pid} }    
  end


  #####################
  #                   #
  # wall_e ROBOT states #
  #                   #
  #####################


  #
  # SYNCHRONOUS State Callbacks
  #

  # 1) 
  def neutral_wall_e(:game_keep_guessing, _from, {player, pid}) do

    case game_start_or_over_check(player) do
      {:game_start} -> 
      	player = Player.start(player)
        reply = Player.round_status(player)
        { :reply, reply, :intrigued_wall_e, {player, pid} }
      
      {:game_over} ->
        reply = Player.game_over_status(player)
        { :reply, reply, :zen_wall_e, {player, pid}}

      _ -> 
        { :reply, "Shouldn't be here", :neutral_wall_e, {player, pid}}
    end
  end

  # 2) 
  def intrigued_wall_e(:game_keep_guessing, _from, {player, pid}) do

    player = Player.robot_guess(player)
    {status_code, _} = reply = Player.round_status(player)
    
    next = 
      case status_code do
        :game_keep_guessing -> :intrigued_wall_e
        :game_won -> :neutral_wall_e
        :game_lost -> :neutral_wall_e
      end
      
    { :reply, reply, next, {player, pid} }
  end

  # 3)
  def zen_wall_e(:game_keep_guessing, _from, {player, pid}) do
    { :reply, {:game_reset, "GAME RESET"}, :zen_wall_e, {player, pid}}
  end

  #
  # ASYNCHRONOUS State Callbacks
  #

  # 1) 
  def neutral_wall_e(:game_keep_guessing, {player, echo_pid}) do

    case game_start_or_over_check(player) do

      {:game_start} -> 
        player = Player.start(player)
        Echo.echo_guess(echo_pid, self()) # Setup the next async echo event

        { :next_state, :spellbound_wall_e, {player, echo_pid} }

      {:game_over} ->
        { :next_state, :zen_wall_e, {player, echo_pid} }

      _ -> 
        { :next_state, :neutral_wall_e, {player, echo_pid}}
    end
  end

  # 2)
  def spellbound_wall_e(:game_keep_guessing, {player, echo_pid}) do

    player = Player.robot_guess(player)
    {status_code, _}  = Player.round_status(player)

    next_state = 
      case status_code do
        :game_keep_guessing -> 
          # Setup the next async echo event
          Echo.echo_guess(echo_pid, self())
          :spellbound_wall_e

        :game_won -> 
          # Setup the next async echo event
          Echo.echo_guess(echo_pid, self())
          :neutral_wall_e

        :game_lost -> 
          # Setup the next async echo event
          Echo.echo_guess(echo_pid, self())
          :neutral_wall_e
      end

    { :next_state, next_state, {player, echo_pid} }
  end

  # 3)
  def zen_wall_e(:game_keep_guessing, {player, pid}) do
    { :stop, :normal, {player, pid}}
  end

  # STATE HELPER function(s)

  defp game_start_or_over_check(%Player{} = player) do

    case Player.game_won?(player) or Player.game_lost?(player) do
      
      true -> # Single game finished

        case Player.game_over?(player) do # All games over?
          
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
  # to use the Erlang module :gen_fsm as a behaviour and implement
  # the following functions below


  def handle_event(:stop, _state_name, state) do
    {:stop, :normal, state};
  end

  def handle_event(_event, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_sync_event(:game_over_status, _from, state_name, state = {player, _}) do

    status = Player.game_over_status(player)

    {:reply, status, state_name, state}
  end  

  def handle_sync_event(:game_status, _from, state_name, state = {player, _}) do

    status = Player.round_status(player)

    {:reply, status, state_name, state}
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
