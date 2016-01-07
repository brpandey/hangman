defmodule Hangman.Strategy do

  alias Hangman.Types.WordPass, as: WordPass
  alias Hangman.Counter, as: Counter

	defstruct guessed_letters: MapSet.new, 
		last_guess: "",
		current_pass: %WordPass{}
  	
  # English letter frequency of english letters (wikipedia)
	@eng_letter_freq			%{
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


	def update(%Hangman.Strategy{} = strategy, 
    %WordPass{pass_size: size, pass_tally: tally, pass_only_word_left: last_word} = _pass) do

    Kernel.put_in(strategy.current_pass.pass_size, size)
    Kernel.put_in(strategy.current_pass.pass_tally, tally)
    Kernel.put_in(strategy.current_pass.pass_only_word_left, last_word)

		strategy
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

    """
    Most common letter retrieval strategy with a twist
    Get the first letter with the highest frequency for when the current possible
    hangman word set space is > "small". Twist is added when we combine the english 
    language letter relative frequency.

    For the cases where the word set is less than small, only take the letter whose
    frequencies are less than or equal to half the possible hagman word pass size

    E.g.for size 10, the letter counts would need to be 5 or lower to be chosen

    Doesn't handle tie between letters
    """

    false = Counter.empty?(tally)

    cond do

      pass_size > @word_set_size.small ->

        [{letter1, count1}, {letter2, count2}] = Counter.most_common(tally, 2)

        size_1 = (1 + @eng_letter_freq[letter1]) * count1

        size_2 = (1 + @eng_letter_freq[letter2]) * count2

        if size_2 > size_1, do: {letter2, count2}, else: {letter1, count1}


      true ->
        tuple_list = for {k,v} <- Counter.items(tally), v <= pass_size/2, do: {k,v}

        if Kernel.length(tuple_list) == 0 do 
          tuple_list = for {k,v} <- Counter.items(tally), do: {k,v}
        end

        tally = Counter.new(tuple_list)

        {letter, count} = Counter.most_common(tally, 1)

    end

		#IO.puts "retrieve_best_letter: letter is #{letter}, counts is #{count}, pass_size is #{pass_size}"

		#{letter, count}
  end
end
