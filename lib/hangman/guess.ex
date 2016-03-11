defmodule Guess do
  @moduledoc """
  Module implements `Guess` types
  """

  @type t :: {:guess_letter, String.t} | {:guess_word, String.t} 


  @typedoc """
  Directive doesn't actually contain the `guess`, just the `guess` directive
  """
  
  @type directive :: :guess_last_word | :robot_guess | :choose_letters

  @type option :: {:game_choose_letter, String.t} | {:game_last_word, String.t}

  @typedoc """
  Used by `Round` to understand prior `guess` result
  """

  @type context ::  ({:game_start, secret_length :: pos_integer}) |
  ({:game_keep_guessing, :correct_letter, letter :: String.t, 
    pattern :: String.t, mystery_letter :: String.t}) |
  ({:game_keep_guessing, :incorrect_letter, letter :: String.t})
  
end
