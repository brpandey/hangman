defmodule Hangman.Player do

  @behaviour :gen_fsm

  defmodule State do
    defstruct player_name: "", 
      game_server_pid: Nil, 
      word_engine_pid: Nil,
       
      last_guess: "",
      current_guess_result: Nil, 
      current_game_status: Nil, 
      current_pattern: "", 
      current_status_text: "",
      
      result: ""
  end

  # External API
  def start_link(player_name, game_server_pid, word_engine_pid) do
    :gen_fsm.start_link(__MODULE__, 
      {player_name, game_server_pid, word_engine_pid}, [])
  end

  # Events

  # 1) start guessing
  def robot_guess(player_pid, event = :game_reset) do
    :gen_fsm.send_event(player_pid, :game_reset)
  end

  # 2) keep guessing, last letter correct
  def robot_guess(player_pid, event = {:game_keep_guessing, :correct_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 3) keep guessing, last letter incorrect
  def robot_guess(player_pid, event = {:game_keep_guessing, :incorrect_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 4) keep guessing, last word incorrect
  def robot_guess(player_pid, event = {:game_keep_guessing, :incorrect_word}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 5) game won
  def robot_guess(player_pid, event = :game_won) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 6) game lost
  def robot_guess(player_pid, event = :game_lost) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 7) game_over
  def robot_guess(player_pid, event = :game_over) do
    :gen_fsm.send_event(player_pid, event)
  end

  def hang_up() do
    :gen_fsm.send_event(player_pid, :hang_up)
  end

  # Callbacks

  def init(player_name, game_server_pid, word_engine_pid) do

    letters_to_guess = ["l", "a", "j", "o", "v", "i"]

    state = %State{player_name: player_name, 
                    game_server_pid: game_server_pid, 
                    word_engine_pid: word_engine_pid}

    guess(:game_reset)
    
    { :ok, :start, state }

  end

  # GUESSING_ROBOT state

  # 1) start guessing
  def guessing_robot(:game_reset, state) do

    IO.puts "In State: start {:guess, :game_reset}"

    {^state.player_name, :secret_length, secret_length} =
      Hangman.Server.secret_length(state.game_server_pid)

    Hangman.Strategy.init(secret_length)

    player_action(:robot, {:game_reset})

    { :next_state, :guessing_robot, state }

  end

  # 2) keep guessing, last letter correct
  def guessing_robot({:game_keep_guessing, :correct_letter}, state) do

    # Print game state
    display_status(state)

    player_action(:robot, {:correct_letter, state.last_guess, state.current_pattern})

    { :next_state, :guessing_robot, state }

  end

  # 3) keep guessing, last letter incorrect
  def guessing_robot({:game_keep_guessing, :incorrect_letter}, state) do

    # Print game state
    display_status(state)
        
    player_action(:robot, {:incorrect_letter, state.last_guess, state.current_pattern})

    { :next_state, :guessing_robot, state }

  end

  # 4) keep guessing, last word incorrect
  def guessing_robot({:game_keep_guessing, :incorrect_word}, state) do

    # Print game state
    display_status(state)
        
    player_action(:robot, {:incorrect_word, state.last_guess, state.current_pattern})

    { :next_state, :guessing_robot, state }

  end

  # 5) game won
  def guessing_robot(:game_won, state) do
    
    # Print game state
    display_status(state)

    # Queue up the next next state 
    robot_guess(:game_reset)

    { :next_state, :guessing_robot, state }

  end

  # 5) game won
  def guessing_robot(:game_lost, state) do
    
    # Print game state
    display_status(state)

    # Queue up the next next state 
    robot_guess(:game_reset)

    { :next_state, :guessing_robot, state }

  end

  # 5) game won
  def guessing_robot(:game_over, state) do
    
    # Print game state
    display_game_over_status(state)

    # Queue up the next next state 
    robot_guess(:game_reset)

    { :next_state, :guessing_robot, state }

  end

  # Helpers

  def display_status(state) do
  	IO.puts "#{inspect state.current_status_text}\n"  	
  end

  def display_game_over_status(state) do
  	IO.puts "#{inspect state.result}\n"  	
  end

  def player_action(:robot, decision_params, state) do
  
      case Hangman.Strategy.make_guess(decision_params) do

        {:guess_word, guess_word} ->

          {{^state.player_name, guess_result, game_status, pattern, text}, final} =
            Hangman.Server.guess_word(state.game_server_pid, guess_word)

        {:guess_letter, guess_letter} ->

          {{^state.player_name, guess_result, game_status, pattern, text}, final} =
            Hangman.Server.guess_letter(state.game_server_pid, guess_letter)
      
      end

    # Queue up the next next state 
    robot_guess(game_status, guess_result, guess_letter, pattern, text)

  end

  def player_action(:human, decision_params, state) do
  	
  end


  # Since Elixir no longer supports GenFSM, we need to use
  # the Erlang module :gen_fsm as a behaviour and implement
  # the following functions below


  def handle_event(_event, state_name, state) do
    {:next_state, state_name, state}
  end

  def handle_sync_event(_event, _from, state_name, state) do
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


defmodule Strategy do
  #Helper function

  def make_guess({:correct_letter, state.last_guess, state.current_pattern}) do

  end

  def make_guess({:incorrect_letter, state.last_guess, state.current_pattern}) do
  	
  end

  def make_guess({:incorrect_word, state.last_guess, state.current_pattern}) do
  	
  end

end