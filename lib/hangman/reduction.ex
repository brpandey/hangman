defmodule Hangman.Reduction do
  @moduledoc """
  Module implements `Reduction` `key` type.
  """

  @typedoc "Defines `key` type format used to `reduce` words set."
  @type key ::
          [{:start, boolean}, {:secret_length, pos_integer}]
          | [
              {:incorrect_word, word :: String.t()},
              {:guessed_letters, MapSet.t()},
              {:regex_match_key, Regex.t()}
            ]
          | [
              {:incorrect_letter, l :: String.t()},
              {:guessed_letters, MapSet.t()},
              {:regex_match_key, Regex.t()}
            ]
          | [
              {:correct_letter, l :: String.t()},
              {:guessed_letters, MapSet.t()},
              {:regex_match_key, Regex.t()}
            ]
end
