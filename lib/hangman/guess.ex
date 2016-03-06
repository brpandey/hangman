defmodule Hangman.Guess do
  @moduledoc """
  Module implements guess abstraction types only
  """

  @type t :: {:guess_letter, String.t} | {:guess_word, String.t}

  @type context ::  ({:game_start, secret_length :: pos_integer}) |
  ({:game_keep_guessing, :correct_letter, letter :: String.t, 
    pattern :: String.t, mystery_letter :: String.t}) |
  ({:game_keep_guessing, :incorrect_letter, letter :: String.t})
  
end
