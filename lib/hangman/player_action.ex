defprotocol Hangman.Player.Action do
  @moduledoc """
  Typeclass for specific player functionality

  The Player Action protocol is implemented for the Human and Robot types, with
  the generic Player handling all overlaps in functionality.  

  Enables custom player implementations

  Function names are `setup/1`, `guess/2`
  """

  @doc "Sets up each action state"
  def setup(player)

  @doc "Returns player guess"
  def guess(player, guess \\ nil)
end
