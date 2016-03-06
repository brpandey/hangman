defmodule Hangman.Game do
  @moduledoc """
  Module simply defines constant
  """

	@mystery_letter "-"

  # Returns module attribute constant
  @spec mystery_letter :: String.t
	def mystery_letter, do: @mystery_letter
  
end
