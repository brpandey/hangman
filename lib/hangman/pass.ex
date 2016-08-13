defmodule Hangman.Pass do
  @moduledoc """
  Module defines types `Pass.key` and `Pass.t`
  """

  defstruct size: 0, tally: %{}, possible: "", last_word: ""

  @typedoc "Defines word `pass` type"
  @type t :: %__MODULE__{}

  @typedoc "Defines word `pass` key type"
  @type key  :: {id :: String.t, game_no :: pos_integer, round_no :: pos_integer}  


  def increment_key({id, game_num, round_num} = _key) do
    {id, game_num, round_num + 1}
  end

end
