defmodule Hangman.Guess do
  @moduledoc "Module implements `Guess` types"

  @type t :: {:guess_letter, String.t} | {:guess_word, String.t}

end
