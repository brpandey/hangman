defmodule Hangman.Reduction.Options do
  @moduledoc """
  Module generates `Reduction` key for use when reducing 
  possible `Hangman` words set. Used primarily during `Round` setup.
  """

  alias Hangman.{Reduction, Round}

  @doc """
  Generates `Reduction.key` given round context
  """

  @spec reduce_key(Round.context, exclusion :: Enumerable.t) :: Reduction.key
  def reduce_key({:start, secret_length} = _context, _letters) do
    
    Keyword.new([
      {:start, true},
      {:secret_length, secret_length}
    ])
  end
  
  def reduce_key({_, :correct_letter, guess, _pattern, 
                  _mystery_letter} = context, letters) do
    
    letters = letters |> Enum.into(MapSet.new)

    # generate regex match key given context to be used to reduce words set
    regex = regex_match_key(context, letters)
    
    Keyword.new([
      {:correct_letter, guess}, 
      {:guessed_letters, letters},
      {:regex_match_key, regex}
    ])
  end
  
  def reduce_key({_, :incorrect_letter, guess} = context, 
                 letters) do

    letters = letters |> Enum.into(MapSet.new)

    # generate regex match key given context to be used to reduce words set    
    regex = regex_match_key(context, letters)
    
    Keyword.new([
      {:incorrect_letter, guess},
      {:guessed_letters, letters},
      {:regex_match_key, regex}
    ])
  end
  

  def reduce_key({_, :incorrect_word, guess} = context, letters) do

    letters = letters |> Enum.into(MapSet.new)

    # generate regex match key given context to be used to reduce words set    
    regex = regex_match_key(context, letters)
    
    Keyword.new([
      {:incorrect_word, guess},
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

  For `incorrect word` last guess, we create a regex which
  does not match the incorrect word. 

  This happens for a last word provided that is not the actual last word,
  because the actual word is not found in the dictionary. This serves
  to cleanly zero out the possible hangman words left in the reduction engine.

  We create a `regex` key to reflect this information.
  """

  @spec regex_match_key(Round.context, Enumerable.t) :: Regex.t

  def regex_match_key({_, :correct_letter, _guess, pattern, mystery_letter}, 
                      guessed_letters) do
    pattern = String.downcase(pattern)
    
    replacement = "[^" <> Enum.join(guessed_letters) <> "]"
    
    # For each mystery_letter replace it with [^characters-already-guessed]
    updated_pattern = String.replace(pattern, mystery_letter, replacement)
    Regex.compile!("^" <> updated_pattern <> "$")
  end

  def regex_match_key({_, :incorrect_letter, incorrect_letter}, _guessed_letters) do    
    # If "E" was the incorrect letter, the pattern would be "^[^E]*$"
    # Starting from the beginning of the string to the end, any string that 
    # contains an "E" will fail false-> Regex.match?(regex, "HELLO") 
    
    pattern = "^[^" <> incorrect_letter <> "]*$"
    Regex.compile!(pattern)
  end
  
  def regex_match_key({_, :incorrect_word, incorrect_word}, _guessed_letters) do    
    # If "overflight" was the incorrect word, the pattern would be "^(overflight)$"
    # Starting from the beginning of the string to the end, any string that 
    # contains an "E" will fail false-> Regex.match?(regex, "HELLO") 
    
    pattern = "^(?!" <> incorrect_word <> "$)"
    Regex.compile!(pattern)
  end
end
