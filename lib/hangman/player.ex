defmodule Hangman.Player do

  @behaviour :gen_fsm

  defmodule State do
    defstruct player_name: "", 
      game_server_pid: Nil, 
      word_engine_pid: Nil,
       
      current_guess: "",
      current_guess_result: Nil, 
      current_game_status: Nil, 
      current_pattern: "", 
      current_text: "",
      
      result: ""
  end

  # External API
  def start_link(player_name, game_server_pid, word_engine_pid) do
    :gen_fsm.start_link(__MODULE__, 
      {player_name, game_server_pid, word_engine_pid}, [])
  end

  # External events

  def guess(player_pid, event = :game_reset) do
    :gen_fsm.send_event(player_pid, :game_reset)
  end

  # keep guessing, last letter correct
  def guess(player_pid, event = {:game_keep_guessing, :correct_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # keep guessing, last letter incorrect
  def guess(player_pid, event = {:game_keep_guessing, :incorrect_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # keep guessing, last word incorrect
  def guess(player_pid, event = {:game_keep_guessing, :incorrect_word}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # game won
  def guess(player_pid, event = :game_won) do
    :gen_fsm.send_event(player_pid, event)
  end

  # game lost
  def guess(player_pid, event = :game_lost) do
    :gen_fsm.send_event(player_pid, event)
  end

  # game_over
  def guess(player_pid, event = :game_over) do
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

  # GUESS state

  def guessing(:game_reset, state) do

    IO.puts "In State: start {:guess, :game_reset}"

    {^state.player_name, :secret_length, secret_length} =
      Hangman.Server.secret_length(state.game_server_pid)

    Hangman.Strategy.init(secret_length)

    player_action(:default, {:game_reset})

    { :next_state, :guess, state }

  end

  # keep guessing, last letter correct
  def guessing({:game_keep_guessing, :correct_letter, 
    correct_letter, pattern, text, []}, state) do

    # Print game state
    IO.puts "#{text}\n"
        
    player_action(:default, {:correct_letter, correct_letter, pattern, text})

    { :next_state, :guess, state }

  end

  # game won, last letter correct
  def guessing({:game_won, :correct_letter, correct_letter, pattern, text, []}, state) do
    
    # Print game state
    IO.puts "#{text}\n"

    # Queue up the next next state 
    guess(:game_reset)

    { :next_state, :guess, state }

  end

  # game won, last letter correct and game over
  def guessing({:game_won, :correct_letter, correct_letter, pattern, text, result}, state) do
    
    # Print game state
    IO.puts "#{text}\n"

    # Queue up the next next state 
    guess(:game_over, result)

    { :next_state, :guess, state }

  end

  # keep guessing, last letter incorrect
  def guessing({:game_keep_guessing, :incorrect_letter, incorrect_letter}) do
    
    # Print game state
    IO.puts "#{text}\n"
        
    player_action(:default, {:correct_letter, correct_letter, pattern, text})

    { :next_state, :guess, state }

  end


  # LISTENING state

  def listening(:hang_up, call_info) do
    action("Hangup", call_info)
    { :next_state, :start, nil }

  end

   def listening(:suspicious_phrase_heard, call_info) do
    action("Heard something suspicious, starting transcription", call_info)
    { :next_state, :transcribing,                              
      call_info = %{ call_info | 
                     suspicious_segments: call_info.suspicious_segments + 1}, 
      @timeout }
  end

  # TRANSCRIBING state
  def transcribing(:hang_up, call_info) do
    action("Report on call", call_info)
    { :next_state, :start, CallInfo.new }

  def transcribing(:suspicious_phrase_heard, call_info) do
    action("More suspicious stuff, extending timeout", call_info)
    { :next_state, :transcribing, call_info, @timeout } 
  end

  def transcribing(:timeout, call_info) do     
    action("Stopping transcription", call_info)
    :gen_fsm.send_event(player_pid, :hang_up)
    { :next_state, :listening, call_info }
  end


  # Helpers
  # {:guess, :game_keep_guessing, :correct_letter, 
  # correct_letter, pattern, text, []}, state

  def player_action(:default, current_game_context)
  
      case Hangman.Strategy.make_guess(current_game_context) do

        {:guess_word, guess_word} ->

          {{^state.player_name, guess_result, game_status, pattern, text}, final} =
            Hangman.Server.guess_word(state.game_server_pid, guess_word)

        {:guess_letter, guess_letter} ->

          {{^state.player_name, guess_result, game_status, pattern, text}, final} =
            Hangman.Server.guess_letter(state.game_server_pid, guess_letter)
      
      end

    # Queue up the next next state 
    guess(game_status, guess_result, guess_letter, pattern, text)

  end


  # Strategy.make_guess


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

  defp _make_guess(guess_code, pattern) do

    case Hangman.Strategy.next_guess(guess_code, pattern) do
      {:word, word} ->
        Hangman.Server.guess_word word
        
      {:letter, letter} ->
        Hangman.Server.guess_letter letter
    end
  end


  defp _next_guess(guess_code, pattern) do
    

  end
end