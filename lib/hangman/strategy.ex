defmodule Hangman.Letter.Strategy do

  @moduledoc """
  Module provides access to a set of functions handling 
  letter guessing strategy.

  From `Wikipedia`

  In the English language, the twelve most commonly occurring letters are, 
  in descending order: e-t-a-o-i-n-s-h-r-d-l-u. This and other letter-frequency 
  lists are used by the guessing player to increase the odds when it is their 
  turn to guess. On the other hand, the same lists can be used by the puzzle 
  setter to stump their opponent by choosing a word which deliberately avoids 
  common letters (e.g. rhythm or zephyr) or one that contains rare letters 
  (e.g. jazz).

  Another common strategy is to guess vowels first, as English only has five 
  vowels (a, e, i, o, and u, while y may sometimes, but rarely, be used as
  a vowel) and almost every word has at least one.

  According to a 2010 study conducted by Jon McLoone for Wolfram Research, the 
  most difficult words to guess include jazz, buzz, hajj, faff, fizz, fuzz and
  variations of these.

  NOTE: For the implementation, letter-frequency lists are primarily used.  A
  vowel strategy is not explicitly used, and perhaps is utilized implicitly 
  through letter-frequency lists.  No effort at this point is made to stump
  the player.

  For the `robot` player type, the strategy retrieves the best letter 
  considering `English` letter frequencies and letter tally counts.

  For the `human` player type, the strategy retries a set of top letter 
  choices to be presented to `human` to manually choose.
  """

  alias Hangman.{Counter, Guess, Pass, Letter.Strategy}

  defstruct type: nil, guessed_letters: MapSet.new, pass: %Pass{}, 
    prior_guess: {}, guess: {}

  @opaque t :: %__MODULE__{}

  @type result :: {t, Guess.t}

  # English letter frequency of english letters (Wikipedia)
  @eng_letter_freq      %{
    "a" => 8.167, "b" => 1.492, "c" => 2.782, "d" => 4.253, "e" => 12.702, 
    "f" => 2.228, "g" => 2.015, "h" => 6.094, "i" => 6.966, "j" => 0.153,
    "k" => 0.772, "l" => 4.025, "m" => 2.406, "n" => 6.749, "o" => 7.507,
    "p" => 1.929, "q" => 0.095, "r" => 5.987, "s" => 6.327, "t" => 9.056,
    "u" => 2.758, "v" => 0.978, "w" => 2.360, "x" => 0.150, "y" => 1.974,
    "z" => 0.074}
  
  @word_set_size    %{micro: 2, tiny: 5, small: 9, large: 550}
  
  @top_threshhold   2
  @letter_choices 5

  # CREATE
  @doc """
  Returns a new `Letter.Strategy`
  """

  @spec new(atom) :: t
  def new(type) when is_atom(type), do: %Strategy{type: type}

  # READ

  @docp """
  If we have reached the last possible hangman word,
  return it so we can guess it
  """

  @spec last_word?(t) :: Guess.t
  defp last_word?(%Strategy{} = strategy) do
    if strategy.pass.size == 1 do
      {true, {:guess_word, strategy.pass.last_word}}
    else
      {false, nil}
    end
  end

  @doc """
  Returns a list of guessed letters up to this point
  """

  @spec guessed(t) :: MapSet.t
  def guessed(%Strategy{} = strategy) do
    strategy.guessed_letters
  end

  # Helpers
  @doc """
  Returns most common `n` letters along with their `counts`
  """

  @spec most_common(t, pos_integer) :: Keyword.t
  def most_common(%Strategy{} = strategy, n) 
  when is_number(n) and n > 0 do
    counter = strategy.pass.tally

    Counter.most_common(counter, n)
  end

  @doc """
  Validates `letter` is within the top strategy letter choices.
  If not, picks the top `letter` as deemed by heuristics.
  """

  @spec validate(t, pos_integer, String.t) :: Guess.t
  def validate(%Strategy{} = strategy, letter, n \\ @letter_choices) 
  when is_number(n) and n > 0 and is_binary(letter) do

    counter = strategy.pass.tally
    top_choices = Counter.most_common_key(counter, n)

    # If user has decided to put in a letter, not in the choices
    # grab the letter that had the highest letter counts
    letter = 
      unless letter in top_choices do Kernel.hd(top_choices) else letter end
    
    {:guess_letter, letter}
  end

  @doc """
  Retrieves letter choices text.  Denotes
  'strategic' letter pick with an `asterisk`.
  """

  @spec choices(t, pos_integer) :: Guess.option
  def choices(%Strategy{} = strategy, n \\ @letter_choices)
  when is_number(n) and n > 0 do
    
    case last_word?(strategy) do        
      {false, _} ->
        
        # Return top 5 {letter, count} pairs if possible
        top_choices = most_common(strategy, n)        

        wrap = if String.length(strategy.pass.possible) > 0 do "\n\n" else "" end
        
        possible_words_txt = strategy.pass.possible <> wrap
        
        size = length(top_choices)      
        choices_text = Enum.reduce(top_choices, "", fn {k,v}, acc -> 
          acc <> " #{k}:#{v}" end)
        
        best_letter = optimal(strategy)        
        choices_text = String.replace(choices_text, best_letter, best_letter <> "*")

        text = possible_words_txt <>
          "Player {name}, Round {round_no}, {status}.\n" <>
          "#{size} weighted letter choices : #{choices_text}" <> 
          " (* robot choice)"
        
        {:guess_letter, text}

      {true, {:guess_word, last}} ->

        text = "Player {name}, Round {round_no}, {status}.\n" <>
          "Last word left: #{last}"

        {:guess_word, last, text}
    end
  end



  @docp """
  Returns optimal letter

  Method implements the most `common` letter retrieval strategy with a twist.
  Gets the first letter with the highest frequency for when the 
  current possible `Hangman` word set space is > "small". 
  The twist is when we combine the `English` language letter relative 
  frequency. For the cases where the word set is less than `small`, 
  takes the letter whose frequencies are less than or equal to half 
  the possible `Hangman` word pass `size`.
  
  E.g.for size 10, the letter `counts` would need to be 5 
  or lower to be chosen. Doesn't handle tie between letters.
  """

  @spec optimal(t) :: String.t
  defp optimal(%Strategy{} = strategy) do

    tally = strategy.pass.tally
    pass_size = strategy.pass.size
    
    if Counter.empty?(tally) do
      raise HangmanError, 
      "Word not in dictionary, no words left (tally is empty)"
    end
    
    cond do
      pass_size > @word_set_size.small ->
        
        [{letter1, count1}, {letter2, count2}] = Counter.most_common(tally, 2)
        
        size_1 = ( 1 + @eng_letter_freq[letter1] ) * count1
        size_2 = ( 1 + @eng_letter_freq[letter2] ) * count2
        
        if size_2 > size_1, do: letter2, else: letter1
      true ->
        # counter is the generator, pass_size/2 is filter guard
        # grab those key value pairs where value is <= 1/2 pass size

        # returns pairs list
        kv_list = 
        for {k,v} <- Counter.items(tally), v <= pass_size/2 do {k,v} end
                      
        # if no pairs in our list, remove the filter guard and run again
        kv_list = 
        if Kernel.length(kv_list) == 0 do
          for {k,v} <- Counter.items(tally) do {k,v} end
        else kv_list end
        
        # retrieve letter with highest frequency count
        tally = Counter.new(kv_list)
        [letter] = Counter.most_common_key(tally, 1)
        
        letter
    end
  end



  # UPDATE

  @docp """
  sets up best letter guess as deemed by heuristics
  """

  @spec setup(t) :: t
  defp setup(%Strategy{} = strategy) do

    strategy = 
      case strategy.pass.size do 
        0 ->  raise HangmanError, "Word not in dictionary"
        1 ->
          {true, {:guess_word, final_word}} = last_word?(strategy)
          
          if {:guess_word, final_word} != strategy.prior_guess 
          and {} != strategy.prior_guess
          and MapSet.size(strategy.guessed_letters) > 0 do
            Kernel.put_in(strategy.guess, {:guess_word, final_word})        
          else
            raise HangmanError, "Exhausted all words, word not in dictionary"
          end

        _pass_size ->
          letter = optimal(strategy)
          
          if letter != nil and letter != "" 
          and {:guess_letter, letter} != strategy.prior_guess do
            guessed_letters = MapSet.put(strategy.guessed_letters, letter)
            
            strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
            Kernel.put_in(strategy.guess, {:guess_letter, letter})            
          else
            raise HangmanError, "Unable to determine next guess as no valid letter left"
          end
      end
    
    strategy
  end

  @doc """
  Returns best letter guess as deemed by heuristics
  """

  @spec guess(t) :: Guess.t
  def guess(%Strategy{} = strategy), do: strategy.guess

  @doc """
  Updates strategy with guess particulars
  """

  @spec update(t, Guess.t) :: t
  def update(%Strategy{} = strategy, {:guess_letter, guessed_letter})
  when is_binary(guessed_letter) do

    guessed_letters = MapSet.put(strategy.guessed_letters, guessed_letter)
    
    strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
    strategy = Kernel.put_in(strategy.guess, {:guess_letter, guessed_letter}) 
    
    strategy
  end

  def update(%Strategy{} = strategy, {:guess_word, last_word})
  when is_binary(last_word) do
    %Strategy{strategy | guess: {:guess_word, last_word}}
  end

  @doc """
  Updates `strategy` with engine `pass` data.

  For `robot` player type, when we updated the pass data
  also `prepare` the guess.
  """

  @spec update(t, Pass.t) :: t

  def update(%Strategy{} = strategy, %Pass{} = pass) do
    strategy = %Strategy{ strategy | pass: pass, prior_guess: strategy.guess }
    
    if strategy.type == :robot do strategy = setup(strategy) else strategy end

  end


  @doc """
  Returns `Strategy` information
  """

  @spec info(t) :: Keyword.t
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

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Strategy.info(t), opts)
      concat ["#Strategy<", info, ">"]
    end
  end

  
end
