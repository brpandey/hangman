defmodule Hangman.Player do
  @behaviour :gen_fsm

  defmodule State do
    defstruct player_name: "", 
      game_server_pid: Nil, 
      word_engine_pid: Nil,
       
      last_guess: "",
      current_guess: "",
      current_guess_result: Nil, 
      current_game_status: Nil, 
      current_pattern: "", 
      current_status_text: "",
      
      final_result: ""
  end

  # External API
  def start_link(player_name, game_server_pid, word_engine_pid) do
    :gen_fsm.start_link(__MODULE__, 
      {player_name, game_server_pid, word_engine_pid}, [])
  end

  # Events

  # 1) start guessing
  def robot_guess(player_pid, event = :game_reset) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 2) keep guessing, last letter correct
  def robot_guess(player_pid, event = {:game_keep_guessing, :correct_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 3) keep guessing, last letter incorrect
  def robot_guess(player_pid, event = {:game_keep_guessing, :incorrect_letter}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 4) game won
  def robot_guess(player_pid, event = {:game_won, guess_result}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 5) game lost
  def robot_guess(player_pid, event = {:game_lost, guess_result}) do
    :gen_fsm.send_event(player_pid, event)
  end

  # 6) game_over
  def robot_guess(player_pid, event = :game_over) do
    :gen_fsm.send_event(player_pid, event)
  end

  # Callbacks

  def init(player_name, game_server_pid, word_engine_pid) do

    state = %State{player_name: player_name, 
                    game_server_pid: game_server_pid, 
                    word_engine_pid: word_engine_pid}

    robot_guess(self(), :game_reset)
    
    { :ok, :guessing_robot, state }

  end

  # GUESSING_ROBOT state

  # 1) start guessing
  def guessing_robot(:game_reset, state) do

    IO.puts "In State: start {:guess, :game_reset}"

    player = state.player_name

    {^player, :secret_length, secret_length} =
      Hangman.Server.secret_length(state.game_server_pid)

    {^player, :game_keep_guessing, status} = 
			Hangman.Server.game_status(state.game_server_pid)

		display_status(status) # Print game state
    player_action(:robot, {:game_reset, secret_length}, state)
    { :next_state, :guessing_robot, state }

  end

  # 2) keep guessing, last letter correct
  def guessing_robot({:game_keep_guessing, :correct_letter}, state) do

    display_status(:game_keep_guessing, state) # Print game state
    player_action(:robot, {:correct_letter, state.last_guess, state.current_pattern}, state)
    { :next_state, :guessing_robot, state }

  end

  # 3) keep guessing, last letter incorrect
  def guessing_robot({:game_keep_guessing, :incorrect_letter}, state) do

    display_status(:game_keep_guessing, state) # Print game state
    player_action(:robot, {:incorrect_letter, state.last_guess, state.current_pattern}, state)
    { :next_state, :guessing_robot, state }

  end

  # 4) game won
  def guessing_robot({:game_won, _}, state) do
    
    display_status(:game_won, state) # Print game state
    robot_guess(self(), :game_reset) # Queue up the next event 
    { :next_state, :guessing_robot, state }

  end

  # 5) game lost
  def guessing_robot({:game_lost, _}, state) do
    
    display_status(:game_lost, state) # Print game state
    robot_guess(self(), :game_reset) # Queue up the next event 
    { :next_state, :guessing_robot, state }

  end

  # 6) game over
  def guessing_robot(:game_over, state) do
    
    display_status(:game_over, state) # Print game state
    robot_guess(self(), :game_reset)     # Queue up the next event 
    { :next_state, :guessing_robot, state }

  end

  # Helpers
	def display_status(text) when is_binary(text) do
  	IO.puts "#{text}\n"  	
  end

  def display_status(:game_over, state) do
  	IO.puts "#{inspect state.result}\n"  	
  end

  def display_status(_, state) do
  	IO.puts "#{inspect state.current_status_text}\n"  	
  end


  def player_action(:robot, decision_params, state) do
  
  	player = state.player_name	

    case Hangman.Strategy.make_guess(decision_params) do

      {:guess_word, guess_word} ->

      	guess = guess_word

        {{^player, guess_result, game_status, pattern, text}, final} =
          Hangman.Server.guess_word(state.game_server_pid, guess_word)

      {:guess_letter, guess_letter} ->

      	guess = guess_letter

        {{^player, guess_result, game_status, pattern, text}, final} =
          Hangman.Server.guess_letter(state.game_server_pid, guess_letter)
    
    end

    state = %State{ state | 
    	last_guess: state.current_guess,
      current_guess: guess,
      current_guess_result: guess_result, 
      current_game_status: game_status, 
      current_pattern: pattern, 
      current_status_text: text,
      final_result: final
		}



    # Queue up the next event 
    robot_guess(self(), {game_status, guess_result})
    
    # Queue up the next next event, if game_over
    case final do 
    	[] -> Nil
    	_ -> 
    		if Keyword.fetch!(final, :status) == :game_over do
    			robot_guess(self(), :game_over) 
 				end
    end

    Nil
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
	alias Hangman.Counter, as: Counter

	@english_letter_frequency			%{
		"a": 8.167, "b": 1.492, "c": 2.782, "d": 4.253, "e": 12.702, 
		"f": 2.228, "g": 2.015, "h": 6.094, "i": 6.966, "j": 0.153,
		"k": 0.772, "l": 4.025, "m": 2.406, "n": 6.749, "o": 7.507,
		"p": 1.929, "q": 0.095, "r": 5.987, "s": 6.327, "t": 9.056,
		"u": 2.758, "v": 0.978, "w": 2.360, "x": 0.150, "y": 1.974,
		"z": 0.074}
  
	@word_set_size		%{micro: 2, tiny: 5, small: 9, large: 550}
	
	@top_threshhold		2


  defmodule State do
  	defstruct last_guess: "",
  						robot_guessed_letters: HashSet.new, 
							current_pass_size: 0,
							letter_counts: Counter.new

	end

  def make_guess({:game_reset, secret_length}) do
  	
  	#Hangman.WordEngine.setup(secret_length)

  end

  def make_guess({:correct_letter, last_guess, pattern}) do

  end

  def make_guess({:incorrect_letter, last_guess, pattern}) do
  	
  end

  def prepare_filter(pattern) do

  	guessed_letters = MapSet.new

  	MapSet.put(guessed_letters, "A")
  	MapSet.put(guessed_letters, "C")

  	exclude_str = Enum.join(guessed_letters)
  	replacement = Enum.join(["[^", exclude_str, "]"])


  	# For each mystery_letter replace it with [^characters already guessed]
  	updated_pattern = String.replace(pattern, Hangman.Server.mystery_letter, replacement)
  	re_pat = Enum.join(['^', updated_pattern ,'$'])

  	regex = Regex.compile!(re_pat)

  	#Regex.match?(regex, word)
  	
  	'''
		# Create a counter object for current state of correct hangman letters
		# Make sure we don't track mystery display letters
		hangman_tally = Counter(hangman_pattern)
		del hangman_tally[self._mystery_letter]

		# Create string representation of set
		exclude_str = ''.join(str(x) for x in self._guessed_letters)

		# For each mystery_letter replace it with [^characters already guessed]
		repat = '^' + hangman_pattern.replace(self._mystery_letter, '[^' + exclude_str + ']') + "$"

		regex = re.compile(repat)
		'''
  end

  def filter_word_space do
		'''
		# Use for filtering sequence
		pass_params_tuple_vector = (last_guess_correct, self._last_guess, \
			hangman_pattern, hangman_tally, regex, self._guessed_letters)

		self._engine.set_pass_params(pass_params_tuple_vector)

		# Reduce the engine word set
		tally, pass_size, self._last_word = self._engine.reduce()

		# Record the counts
		self.set_letter_counts(pass_size, tally)
		'''
  end

  def process_filter_results do
  	
  	'''
  	if pass_size == 0: 
			error = "Game over, exhausted all words, word not in dictionary"
			#raise Exception("Word not in dictionary")

		elif pass_size == 1:
			if self._guessed_last_word != True:
				word = self._last_word
				guess = GuessWord(word)
				self._last_guess = word
				self._guessed_last_word = True
			else: 
				error = "Game over, exhausted all words, word not in dictionary"


		# most of the game play is where the pass size hasn't dwindled down to 0 or 1
		else:
			tally = self._letter_counts
			letter = self.__get_letter(tally, pass_size)

			if self._display.ischatty():
				self._display.chatty("letter counts are {}".format(tally))
				self._display.chatty("guess character is {}".format(letter))

			if letter != None:
				guess = GuessLetter(letter)
				self._guessed_letters.add(letter)
				self._last_guess = letter
			else:
				raise Exception("Unable to determine next guess")
  	'''
  end

  def retrieve_best_letter do
  	'''
  	assert(sum(tally.values()) > 0 and pass_size > 1)

		letter, count = self.__letter_most_common_hybrid(tally, pass_size)

		msg = "letter is {}, counts is {}, pass_size is {}"
		self._display.chatty(msg.format(letter, count, pass_size))

		return letter
  	'''
  end

end