defmodule Hangman.Pass do
  @moduledoc """
  Module implements pass abstraction types and pass module struct
  """


  @typedoc """
  Defines reduction pass and pass type
  """
  
  defstruct size: 0, tally: %{}, possible: "", last_word: ""
  
  @type t :: %__MODULE__{}


  @typedoc """
  Define reduction pass key type
  """

  @type key  :: {id :: String.t, game_no :: pos_integer, round_no :: pos_integer}  


end
