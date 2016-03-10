defmodule Guess do
  @moduledoc """
  Module implements guess types
  """

  @type t :: {:guess_letter, String.t} | {:guess_word, String.t} 


  @typedoc """
  Directive doesn't actually contain the guess, just direction
  """
  
  @type directive :: :guess_last_word | :robot_guess | :choose_letters

  @type option :: {:game_choose_letter, String.t} | {:game_last_word, String.t}

  @typedoc """
  Used by round abstraction to understand previous guess results
  """

  @type context ::  ({:game_start, secret_length :: pos_integer}) |
  ({:game_keep_guessing, :correct_letter, letter :: String.t, 
    pattern :: String.t, mystery_letter :: String.t}) |
  ({:game_keep_guessing, :incorrect_letter, letter :: String.t})
  
end
