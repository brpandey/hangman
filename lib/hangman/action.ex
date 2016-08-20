defmodule Hangman.Action do

  @moduledoc """
  Defines the `Action` typeused in Player.Action
  """

  @type t :: %__MODULE__{}

  defstruct type: nil, display: false, round: nil, strategy: nil


end
