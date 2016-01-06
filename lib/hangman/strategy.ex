defmodule Hangman.Strategy do

  alias Hangman.Types.WordPass, as: WordPass
  alias Hangman.Counter, as: Counter

	defstruct guessed_letters: MapSet.new, 
		last_guess: "",
		current_pass: %WordPass{}
  	

	@english_letter_frequency			%{
		"a": 8.167, "b": 1.492, "c": 2.782, "d": 4.253, "e": 12.702, 
		"f": 2.228, "g": 2.015, "h": 6.094, "i": 6.966, "j": 0.153,
		"k": 0.772, "l": 4.025, "m": 2.406, "n": 6.749, "o": 7.507,
		"p": 1.929, "q": 0.095, "r": 5.987, "s": 6.327, "t": 9.056,
		"u": 2.758, "v": 0.978, "w": 2.360, "x": 0.150, "y": 1.974,
		"z": 0.074}
  
	@word_set_size		%{micro: 2, tiny: 5, small: 9, large: 550}
	
	@top_threshhold		2

	def new() do
		%Hangman.Strategy{}
	end

  def retrieve_guess({:game_start, secret_length}, state) do
  	# This should be moved to player
  	# Hangman.WordEngine.setup(secret_length)
  end

  def word_filter_options(%Hangman.Strategy{ guessed_letters: guessed } = strategy, 
  	{:correct_letter, last_guess, pattern, mystery_letter} = _context) do
  	
  	regex = regex_word_filter(:correct_letter, 
  						String.downcase(pattern), mystery_letter, guessed)

		Keyword.new([
			{:correct_letter, last_guess}, 
			{:guessed_letters, guessed},
			{:regex, regex}
		])
	end

  def word_filter_options(%Hangman.Strategy{ guessed_letters: guessed } = strategy,
  	{:incorrect_letter, last_guess} = _context) do
  	
  	regex = regex_word_filter(:incorrect_letter, last_guess)

		Keyword.new([
			{:incorrect_letter, last_guess}, # leave this in until we are assured the regex is faster
			{:guessed_letters, guessed},
			{:regex, regex}
		])
	end

  # TODO: Move WordPass struct to a separate location so both WordEngine and Strategy can share e.g. Hangman.Types
  # def update(%Hangman.Strategy{} = strategy, %WordPass{} = _pass)

	def word_pass_update(%Hangman.Strategy{} = strategy, {tally, size, last_word} = _pass) do
		current_pass = %WordPass{ 
			pass_size: size, 
			pass_tally: tally, 
			pass_only_word_left: last_word 
		}

		%Hangman.Strategy{ strategy | current_pass: current_pass}
  end

  def make_guess(%Hangman.Strategy{} = strategy) do
  	case strategy.pass_size do 
  		0 ->
  			raise "Word not in dictionary"

  		1 ->
  			if strategy.last_guess != strategy.last_word 
  				and MapSet.size(strategy.guessed_letters) > 0 do
  					word = strategy.last_word
  					strategy = %Hangman.Strategy{ strategy | last_guess: word}

  					{:guess_word, word}
  			else
  				raise "Game over, exhausted all words, word not in dictionary"
  			end

  		_ ->
  			letter = retrieve_best_letter(strategy.letter_tally, strategy.pass_size)
  			
  			if letter != Nil and letter != "" do
  				guessed_letters = MapSet.put(strategy.guessed_letters, letter)
  				strategy = %Hangman.Strategy{ strategy | 
  					guessed_letters: guessed_letters, 
  					last_guess: letter }

  				{:guess_letter, letter}
  			else
  				raise "Unable to determine next guess"
  			end
  	end
  end

  # Helper methods
  defp regex_word_filter(:correct_letter, pattern, mystery_letter, guessed_letters) do

  	replacement = "[^" <> Enum.join(guessed_letters) <> "]"

  	# For each mystery_letter replace it with [^characters already guessed]
  	updated_pattern = String.replace(pattern, mystery_letter, replacement)
  	
  	regex = Regex.compile!("^" <> updated_pattern <> "$")
  end

  defp regex_word_filter(:incorrect_letter, incorrect_letter) do
  		
  	# If "E" was the incorrect letter, the pattern would be "^[^E]*$"
		# Starting from the beginning of the string to the end, any string that 
		# contains an "E" will fail false-> Regex.match?(regex, "HELLO") 

  	pattern = "^[^" <> incorrect_letter <> "]*$"
  	regex = Regex.compile!(pattern)
  end

  defp retrieve_best_letter(tally, pass_size) do

  	false = Counter.empty?(tally)

		#IO.puts "letter is #{letter}, counts is #{count}, pass_size is #{pass_size}"

		#{letter, count}
  end
end
