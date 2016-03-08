defmodule Reduction do
  @moduledoc """
  Module implements reduction abstraction key type only
  """

  @typedoc """
  Defines reduction key type format used to reduce words set
  """
  
  @type key :: ( [{:game_start, boolean}, {:secret_length, pos_integer}] ) |
  ( [{:incorrect_letter, l :: String.t}, {:guessed_letters, MapSet.t}, 
     {:regex_match_key, Regex.t}] ) | 
  ( [{:correct_letter, l :: String.t}, {:guessed_letters, MapSet.t}, 
     {:regex_match_key, Regex.t}] )

end
