defmodule Hangman.Strategy.Options do

  alias Hangman.Strategy, as: Strategy
  alias Hangman.Types.Reduction, as: Reduction

  @spec reduce_key(Strategy.t, tuple) :: Reduction.Key
  def reduce_key(%Strategy{} = _strategy, 
                 {:game_start, secret_length} = _context) do
    
    Keyword.new([
      {:game_start, true},
      {:secret_length, secret_length}
    ])
  end
  
  @spec reduce_key(Strategy.t, tuple) :: Reduction.Key
  def reduce_key(%Strategy{ guessed_letters: guessed } = _strategy, 
                 {_, :correct_letter, guess, _pattern, 
                  _mystery_letter} = context) do
    
    regex = regex_match_key(context, guessed)
    
    Keyword.new([
      {:correct_letter, guess}, 
      {:guessed_letters, guessed},
      {:regex_match_key, regex}
    ])
  end
  
  @spec reduce_key(Strategy.t, tuple) :: Reduction.Key
  def reduce_key(%Strategy{ guessed_letters: guessed } = _strategy,
                 {_, :incorrect_letter, guess} = context) do
    
    regex = regex_match_key(context, guessed)
    
    Keyword.new([
      {:incorrect_letter, guess},
      {:guessed_letters, guessed},
      {:regex_match_key, regex}
    ])
  end
  
  # Helper methods
  @spec regex_match_key(tuple, MapSet.t) :: Regex.t
  def regex_match_key({_, :correct_letter, _guess, pattern, mystery_letter}, guessed_letters) do
    pattern = String.downcase(pattern)
    
    replacement = "[^" <> Enum.join(guessed_letters) <> "]"
    
    # For each mystery_letter replace it with [^characters-already-guessed]
    updated_pattern = String.replace(pattern, mystery_letter, replacement)
    Regex.compile!("^" <> updated_pattern <> "$")
  end
  
  @spec regex_match_key(tuple, MapSet.t) :: Regex.t
  def regex_match_key({_, :incorrect_letter, incorrect_letter}, _guessed) do
    
    # If "E" was the incorrect letter, the pattern would be "^[^E]*$"
    # Starting from the beginning of the string to the end, any string that 
    # contains an "E" will fail false-> Regex.match?(regex, "HELLO") 
    
    pattern = "^[^" <> incorrect_letter <> "]*$"
    Regex.compile!(pattern)
  end
  
end # Options module
