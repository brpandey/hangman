defmodule Reduction.Options do
  @moduledoc """
  Module generates `Reduction` key for use when reducing 
  possible `Hangman` words set. Used primarily during `Round` setup.
  """

  @doc """
  Generates `Reduction.key` given round context
  """

  @spec reduce_key(Guess.context, exclusion :: MapSet.t) :: Reduction.key
  def reduce_key({:game_start, secret_length} = _context, %MapSet{} = _letters) do
    
    Keyword.new([
      {:game_start, true},
      {:secret_length, secret_length}
    ])
  end
  
  def reduce_key({_, :correct_letter, guess, _pattern, 
                  _mystery_letter} = context, %MapSet{} = letters) do
    
    # generate regex match key given context to be used to reduce words set
    regex = regex_match_key(context, letters)
    
    Keyword.new([
      {:correct_letter, guess}, 
      {:guessed_letters, letters},
      {:regex_match_key, regex}
    ])
  end
  
  def reduce_key({_, :incorrect_letter, guess} = context, 
                 %MapSet{} = letters) do

    # generate regex match key given context to be used to reduce words set    
    regex = regex_match_key(context, letters)
    
    Keyword.new([
      {:incorrect_letter, guess},
      {:guessed_letters, letters},
      {:regex_match_key, regex}
    ])
  end
  

  @doc """
  Generates `regex` key to match and filter against possible `Hangman` words

  For `correct` letter last guesses, uses the new updated pattern along with 
  the fact the we know the correct letter along with the previously 
  guessed letters can not be in the `unknown letter positions`.

  For `incorrect` letter last guesses, uses the fact the we know
  the incorrect letter `can not be found anywhere` in the
  possible `Hangman` words.

  We create a `regex` key to reflect this information.
  """

  @spec regex_match_key(Guess.context, exclusion :: MapSet.t) :: Regex.t

  def regex_match_key({_, :correct_letter, _guess, pattern, mystery_letter}, guessed_letters) do
    pattern = String.downcase(pattern)
    
    replacement = "[^" <> Enum.join(guessed_letters) <> "]"
    
    # For each mystery_letter replace it with [^characters-already-guessed]
    updated_pattern = String.replace(pattern, mystery_letter, replacement)
    Regex.compile!("^" <> updated_pattern <> "$")
  end

  def regex_match_key({_, :incorrect_letter, incorrect_letter}, _guessed) do    
    # If "E" was the incorrect letter, the pattern would be "^[^E]*$"
    # Starting from the beginning of the string to the end, any string that 
    # contains an "E" will fail false-> Regex.match?(regex, "HELLO") 
    
    pattern = "^[^" <> incorrect_letter <> "]*$"
    Regex.compile!(pattern)
  end
  
end
