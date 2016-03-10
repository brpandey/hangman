defmodule Pass do
  @moduledoc """
  Module defines words pass types and pass struct
  """

  defstruct size: 0, tally: %{}, possible: "", last_word: ""

  @typedoc """
  Defines word pass type
  """
    
  @type t :: %__MODULE__{}


  @typedoc """
  Defines word pass key type
  """

  @type key  :: {id :: String.t, game_no :: pos_integer, round_no :: pos_integer}  


end
