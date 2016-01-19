defmodule Hangman.Strategy do

  alias Hangman.{Counter, Types.Reduction.Pass}

	defstruct guessed_letters: MapSet.new, pass: %Pass{}, 
    prior_guess: {}, guess: {}
  	
  # English letter frequency of english letters (Wikipedia)
	@eng_letter_freq			%{
		"a" => 8.167, "b" => 1.492, "c" => 2.782, "d" => 4.253, "e" => 12.702, 
		"f" => 2.228, "g" => 2.015, "h" => 6.094, "i" => 6.966, "j" => 0.153,
		"k" => 0.772, "l" => 4.025, "m" => 2.406, "n" => 6.749, "o" => 7.507,
		"p" => 1.929, "q" => 0.095, "r" => 5.987, "s" => 6.327, "t" => 9.056,
		"u" => 2.758, "v" => 0.978, "w" => 2.360, "x" => 0.150, "y" => 1.974,
		"z" => 0.074}
  
	@word_set_size		%{micro: 2, tiny: 5, small: 9, large: 550}
	
	@top_threshhold		2

  # CREATE

	def new(), do: %Hangman.Strategy{}

  # READ

  def last_word(%Hangman.Strategy{} = strategy) do
    
    if strategy.pass.size == 1 do
      strategy.pass.only_word_left      
    else
      Nil
    end

  end

  def make_guess(%Hangman.Strategy{} = strategy), do: strategy.guess

  def prepare_guess(%Hangman.Strategy{} = strategy) do
  	case strategy.pass.size do 
  		0 ->
  			raise "word not in dictionary"

  		1 ->
        final_word = strategy.pass.only_word_left

  			if {:guess_word, final_word} != strategy.prior_guess and {} != strategy.prior_guess
  				and MapSet.size(strategy.guessed_letters) > 0 do

            strategy = Kernel.put_in(strategy.guess, {:guess_word, final_word})        
  			else
  				raise "game over, exhausted all words, word not in dictionary"
  			end

  		_ ->
  			letter = retrieve_best_letter(strategy)
  			
  			if letter != Nil and letter != "" 
          and {:guess_letter, letter} != strategy.prior_guess do
  				guessed_letters = MapSet.put(strategy.guessed_letters, letter)
  				
          strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
          strategy = Kernel.put_in(strategy.guess, {:guess_letter, letter})                    
  			else
  				raise "unable to determine next guess"
  			end
  	end
  end

  # UPDATE

  def update(%Hangman.Strategy{} = strategy, {:letter, human_guessed_letter}) 
    when is_binary(human_guessed_letter) do

      guessed_letters = MapSet.put(strategy.guessed_letters, 
                                    human_guessed_letter)
          
      strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
      strategy = Kernel.put_in(strategy.guess, 
                                  {:guess_letter, human_guessed_letter}) 

      strategy
  end

  def update(%Hangman.Strategy{} = strategy, {:word, last_word}) 
    when is_binary(last_word) do

      strategy = Kernel.put_in(strategy.guess, {:guess_word, last_word})

      strategy
  end

  def update(%Hangman.Strategy{} = strategy, %Pass{} = pass) do
    strategy = %Hangman.Strategy{ strategy | pass: pass, 
                  prior_guess: strategy.guess}

    strategy = prepare_guess(strategy)

    strategy
  end

  # Helpers

  def most_common_letter_and_counts(%Hangman.Strategy{} = strategy, n) 
  when is_number(n) and n > 0 do
    counter = strategy.pass.tally
    Counter.most_common(counter, n)
  end

  def most_common_letter(%Hangman.Strategy{} = strategy, n) 
  when is_number(n) and n > 0 do
    counter = strategy.pass.tally
    Counter.most_common_key(counter, n)
  end

  @doc """
  retrieve_best_letter

    Most common letter retrieval strategy with a twist
    Get the first letter with the highest frequency for when the current possible
    hangman word set space is > "small". Twist is added when we combine the english 
    language letter relative frequency.

    For the cases where the word set is less than small, only take the letter whose
    frequencies are less than or equal to half the possible hagman word pass size

    E.g.for size 10, the letter counts would need to be 5 or lower to be chosen

    Doesn't handle tie between letters
  """

  def retrieve_best_letter(%Hangman.Strategy{} = strategy) do
    do_retrieve_best_letter(strategy.pass.tally, strategy.pass.size)
  end

  defp do_retrieve_best_letter(tally, pass_size) do

    false = Counter.empty?(tally) # Assert

    cond do
      pass_size > @word_set_size.small ->

        [{letter1, count1}, {letter2, count2}] = Counter.most_common(tally, 2)

        size_1 = ( 1 + @eng_letter_freq[letter1] ) * count1
        size_2 = ( 1 + @eng_letter_freq[letter2] ) * count2

        if size_2 > size_1, do: letter2, else: letter1

      true ->
        tuple_list = for {k,v} <- Counter.items(tally), v <= pass_size/2, do: {k,v}

        if Kernel.length(tuple_list) == 0 do 
          tuple_list = for {k,v} <- Counter.items(tally), do: {k,v}
        end

        tally = Counter.new(tuple_list)

        [{letter, _count}] = Counter.most_common(tally, 1)
        
        letter
    end
  end

  defmodule Options do

    def filter_options(%Hangman.Strategy{} = _strategy, 
      {:game_start, secret_length} = _context) do
    
      Keyword.new([
          {:game_start, true},
          {:secret_length, secret_length}
        ])
    end

    def filter_options(%Hangman.Strategy{ guessed_letters: guessed } = _strategy, 
      {:correct_letter, guess, pattern, mystery_letter} = _context) do
      
      regex = regex_word_filter(:correct_letter, 
                String.downcase(pattern), mystery_letter, guessed)

      Keyword.new([
        {:correct_letter, guess}, 
        {:guessed_letters, guessed},
        {:regex, regex}
      ])
    end

    def filter_options(%Hangman.Strategy{ guessed_letters: guessed } = _strategy,
      {:incorrect_letter, guess} = _context) do
      
      regex = regex_word_filter(:incorrect_letter, guess)

      Keyword.new([
        {:incorrect_letter, guess}, # leave this in until we are assured the regex is faster
        {:guessed_letters, guessed},
        {:regex, regex}
      ])
    end

    # Helper methods
    defp regex_word_filter(:correct_letter, pattern, mystery_letter, guessed_letters) do
      replacement = "[^" <> Enum.join(guessed_letters) <> "]"

      # For each mystery_letter replace it with [^characters-already-guessed]
      updated_pattern = String.replace(pattern, mystery_letter, replacement)
      Regex.compile!("^" <> updated_pattern <> "$")
    end

    defp regex_word_filter(:incorrect_letter, incorrect_letter) do
        
      # If "E" was the incorrect letter, the pattern would be "^[^E]*$"
      # Starting from the beginning of the string to the end, any string that 
      # contains an "E" will fail false-> Regex.match?(regex, "HELLO") 

      pattern = "^[^" <> incorrect_letter <> "]*$"
      Regex.compile!(pattern)
    end

  end # inner Options module
end # outer Strategy module
