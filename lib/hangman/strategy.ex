defmodule Hangman.Strategy do

  alias Hangman.{Strategy, Counter, Types.Reduction.Pass}

	defstruct guessed_letters: MapSet.new, pass: %Pass{}, 
    prior_guess: {}, guess: {}

  @type t :: %__MODULE__{}

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

	def new(), do: %Strategy{}

  # READ



  def last_word(%Strategy{} = strategy) do
    if strategy.pass.size == 1 do
      {:guess_word, strategy.pass.last_word}
    else
      {:guess_word, ""}
    end
  end

  def get_guessed(%Strategy{} = strategy) do
    MapSet.to_list(strategy.guessed_letters)
  end

  def possible_words(%Strategy{} = strategy), do: strategy.pass.possible

  # UPDATE

  def make_guess(%Strategy{} = strategy) do
  	case strategy.pass.size do 
  		0 ->	raise Hangman.Error, "Word not in dictionary"
  		1 ->
        final_word = strategy.pass.last_word

  			if {:guess_word, final_word} != strategy.prior_guess 
        and {} != strategy.prior_guess
  			and MapSet.size(strategy.guessed_letters) > 0 do

          strategy = Kernel.put_in(strategy.guess, {:guess_word, final_word})        
  			else
  				raise Hangman.Error, "Exhausted all words, word not in dictionary"
  			end

  		_pass_size ->
  			letter = retrieve_best_letter(strategy)
  			
  			if letter != nil and letter != "" 
          and {:guess_letter, letter} != strategy.prior_guess do
  				guessed_letters = MapSet.put(strategy.guessed_letters, letter)
  				
          strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
          strategy = Kernel.put_in(strategy.guess, {:guess_letter, letter})            
  			else
  				raise Hangman.Error, "Unable to determine next guess as no valid letter left"
  			end
  	end

    {strategy, strategy.guess}
  end

  def update(%Strategy{} = strategy, {:guess_letter, guessed_letter}) 
    when is_binary(guessed_letter) do

      guessed_letters = MapSet.put(strategy.guessed_letters, guessed_letter)
          
      strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
      strategy = Kernel.put_in(strategy.guess, 
                                  {:guess_letter, guessed_letter}) 

      strategy
  end

  def update(%Strategy{} = strategy, {:guess_word, last_word}) 
    when is_binary(last_word) do
    %Strategy{strategy | guess: {:guess_word, last_word}}
  end

  def update(%Strategy{} = strategy, %Pass{} = pass) do
    prior = strategy.guess
    %Strategy{ strategy | pass: pass, prior_guess: prior}
  end

  # Helpers

  def most_common_letter_and_counts(%Strategy{} = strategy, n) 
  when is_number(n) and n > 0 do
    counter = strategy.pass.tally

    Counter.most_common(counter, n)
  end

  def most_common_letter(%Strategy{} = strategy, n) 
  when is_number(n) and n > 0 do
    counter = strategy.pass.tally

    Counter.most_common_key(counter, n)
  end


  def letter_in_most_common(%Strategy{} = strategy, n, letter) 
  when is_number(n) and n > 0 and is_binary(letter) do

    counter = strategy.pass.tally
    top_choices = Counter.most_common_key(counter, n)

    # If user has decided to put in a letter, not in the choices
    # grab the letter that had the highest letter counts
  	unless letter in top_choices, do: letter = Kernel.hd(top_choices)
    
    {:guess_letter, letter}
  end


  def choose_letters(%Strategy{} = strategy, n)
  when is_number(n) and n > 0 do
    
    case Strategy.last_word(strategy) do        
      {:guess_word, ""} ->
        
        # Return top 5 letter, count pairs if possible
        top_choices = Strategy.most_common_letter_and_counts(strategy, n)
        
        possible_words_txt = Strategy.possible_words(strategy)
        
        if String.length(possible_words_txt) > 0 do
          possible_words_txt = possible_words_txt <> "\n\n"
        end
        
        size = length(top_choices)
      
        choices_text = Enum.reduce(top_choices, "", fn {k,v}, acc -> 
          acc <> " #{k}:#{v}" end)
        
        best_letter = Strategy.retrieve_best_letter(strategy)
        
        choices_text = String.replace(choices_text, best_letter, best_letter <> "*")

        text = possible_words_txt <>
          "Player {name}, Round {round_no}, {status}.\n" <>
        	"#{size} weighted letter choices : #{choices_text}" <> 
          " (* robot choice)"
        
        {:game_choose_letter, text}

      {:guess_word, last} ->

        text = "Player {name}, Round {round_no}, {status}.\n" <>
          "Last word left: #{last}"

        {:game_last_word, text}
    end
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

  def retrieve_best_letter(%Strategy{} = strategy) do
    do_retrieve_best_letter(strategy.pass.tally, strategy.pass.size)
  end

  defp do_retrieve_best_letter(tally, pass_size) do

    if Counter.empty?(tally) do
      raise Hangman.Error, 
      "Word not in dictionary, no words left (tally is empty)"
    end

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

        [letter] = Counter.most_common_key(tally, 1)
        
        letter
    end
  end

  def info(%Strategy{} = s) do

    pass_tally_text = 
      case(s.pass.tally) do
        %Counter{} -> Counter.items(s.pass.tally)
        %{} -> []
      end


    pass = [
      size: s.pass.size,
#      possible_words: s.pass.possible,
      last_word: s.pass.last_word,
      tally: pass_tally_text
    ]

    guessed = MapSet.to_list(s.guessed_letters)

    [guessed: guessed, guess: s.guess, pass: pass]
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Strategy.info(t), opts)
      concat ["#Hangman.Strategy<", info, ">"]
    end
  end

  
end
