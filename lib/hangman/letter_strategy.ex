defmodule Hangman.Letter.Strategy do
  @moduledoc """
  Module provides access to a set of functions handling 
  letter guessing strategy.

  (From `Wikipedia`)

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

  alias Hangman.{Counter, Guess, Pass, Letter, Letter.Strategy, Round}
  require Logger

  defstruct guessed_letters: MapSet.new, pass: %Pass{}, guess: {}, choices: {}

  @opaque t :: %__MODULE__{}
  @type result :: {t, Guess.t}

  @letter_choices 5

  # CREATE
  @doc """
  Returns a new `Letter.Strategy`
  """

  @spec new() :: t
  def new(), do: %Strategy{}

  # READ

  @doc """
  Returns a list of guessed letters up to this point
  """

  @spec guessed(t) :: list
  def guessed(%Strategy{} = strategy) do
    strategy.guessed_letters |> Enum.to_list
  end


  # UPDATE

  @doc """
  Process best letter guess as deemed by the auto self-selecting heuristic
  """
  @spec process(t, Pass.t) :: t | no_return
  def process(%Strategy{} = strategy, %Pass{} = pass) do
    process(strategy, :auto, pass)
  end

  @spec process(t, atom, Pass.t) :: t | no_return
  def process(%Strategy{} = strategy, :auto, %Pass{} = pass) do

    # Updates `strategy` with engine `pass` data.
    strategy = %{ strategy | pass: pass }

    strategy = 
      case strategy.pass.size do 
        0 ->  
          raise HangmanError, "Word not in dictionary"
        1 ->
          {true, {:guess_word, final_word}} = last_word?(strategy)
          Kernel.put_in(strategy.guess, {:guess_word, final_word})
        _ ->
          letter = select(strategy)
          guessed_letters = MapSet.put(strategy.guessed_letters, letter)
          strategy = Kernel.put_in(strategy.guessed_letters, guessed_letters)
          Kernel.put_in(strategy.guess, {:guess_letter, letter})            
      end
    
    strategy
  end


  @doc """
  Processes pass data and stores guess choices data. Denotes
  'strategic' letter pick with an `asterisk`.
  """
  
  @spec process(t, atom, Pass.t, pos_integer) :: Guess.option | no_return
  def process(%Strategy{} = strategy, :choices, %Pass{} = pass, n \\ @letter_choices)
  when is_number(n) and n > 0 do

    # Updates `strategy` with engine `pass` data.
    strategy = %{ strategy | pass: pass }

    if strategy.pass.size == 0 do raise HangmanError, "Word not in dictionary" end
    
    strategy = 
      case last_word?(strategy) do        
        {false, _} ->          
          # Return top 5 {letter, count} pairs if possible
          top_choices = strategy.pass.tally |> Counter.most_common(n) 
          
          wrap = if String.length(strategy.pass.possible) > 0 do "\n\n" else "" end
          
          possible_words_txt = strategy.pass.possible <> wrap
          
          size = length(top_choices)      
          choices_text = Enum.reduce(top_choices, "", fn {k,v}, acc -> 
            acc <> " #{k}:#{v}" end)
          
          best_letter = select(strategy)        
          choices_text = String.replace(choices_text, best_letter, best_letter <> "*")
          
          text = possible_words_txt <>
            "Player {name}, Round {round_no}, {status}.\n" <>
            "#{size} weighted letter choices : #{choices_text}" <> 
            " (* robot choice)"
          
          Kernel.put_in(strategy.choices, {:guess_letter, text})

        {true, {:guess_word, last}} ->
          # Return text with last word
          text = "Player {name}, Round {round_no}, {status}.\n" <>
            "Last word left: #{last}"
          
          Kernel.put_in(strategy.choices, {:guess_word, last, text})
      end
    
    strategy
  end


  @doc """
  Returns best letter guess as previously computed
  """

  @spec guess(t) :: Guess.t
  def guess(%Strategy{} = strategy), do: guess(strategy, :auto)

  @spec guess(t, atom) :: Guess.t
  def guess(%Strategy{} = strategy, :auto), do: strategy.guess

  @spec guess(t, atom, tuple) :: Guess.t
  def guess(%Strategy{} = strategy, :choices, {:guess_letter, letter}) do
    validate(strategy, letter)
  end

  def guess(%Strategy{} = _strategy, :choices, {:guess_word, last_word}) 
      when is_binary(last_word) do
    {:guess_word, last_word}
  end


  @doc """
  Updates strategy with guess data
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
    %{ strategy | guess: {:guess_word, last_word}}
  end


  @doc """
  Retrieves choices info augmenting it with round info
  """

  @spec choices(t, Round.t) :: Guess.options
  def choices(%Strategy{} = strategy, %Round{} = round) do
    case strategy.choices do
      {:guess_letter, text} ->
        text = update_choices(round, text)
        {:guess_letter, text}
      {:guess_word, last, text} ->
        text = update_choices(round, text)
        {:guess_word, last, text}
      _ -> raise HangmanError, "Unsupported choices type"
    end
  end


  # PRIVATE HELPERS

  # Defer to letter retrieval strategy to return best letter
  @spec select(t) :: String.t
  defp select(%Strategy{} = strategy) do
    Letter.Retrieval.Strategy.select(strategy)
  end
 

  # If we have reached the last possible hangman word,
  # return it so we can guess it

  @spec last_word?(t) :: tuple
  defp last_word?(%Strategy{} = strategy) do
    if strategy.pass.size == 1 do
      {true, {:guess_word, strategy.pass.last_word}}
    else
      {false, nil}
    end
  end



  # Validates `letter` is within the top strategy letter choices.
  # If not, picks the top `letter` as deemed by heuristics.

  @spec validate(t, String.t, pos_integer) :: Guess.t
  defp validate(%Strategy{} = strategy, letter, n \\ @letter_choices) 
  when is_number(n) and n > 0 and is_binary(letter) do

    counter = strategy.pass.tally
    top_choices = Counter.most_common_key(counter, n)

    # If user has decided to put in a letter, not in the choices
    # grab the letter that had the highest letter counts
    letter = 
      unless letter in top_choices do Kernel.hd(top_choices) else letter end
    
    {:guess_letter, letter}
  end


  # Interjects specific parameters into `choices text`.

  @spec update_choices(Round.t, String.t) :: String.t
  defp update_choices(%Round{} = round, text) when is_binary(text) do
    {name, _, round_no} = Round.round_key(round)
    {_, status_text} = Round.status(round)

    text 
    |> String.replace("{name}", "#{name}")
    |> String.replace("{round_no}", "#{round_no}")
    |> String.replace("{status}", "#{status_text}")
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
