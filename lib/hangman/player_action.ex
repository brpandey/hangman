alias Hangman.Action.{Human, Robot}
alias Hangman.Player

defprotocol Hangman.Player.Action do

  @moduledoc """
  Module implements player action functionality 
  for various player types via protocol mechanism
  
  The Player Action protocol is implemented for the Human and Robot types, with
  the generic Player handling all overlaps in functionality.  
  
  The goal of a player is to maximize our winning chances in conjunction
  with a letter strategy against the 'implicit' other player, the `game server`.
  
  Player action functionality handles choosing letters, guessing letters and words.
  
  `Round` functionality handles the actual game round details along with 
  the Letter.Strategy.

  Function names are `setup/1`, `guess/2`
  """


  @doc "Sets up each action state"
  @spec setup(Player.t(any)) :: tuple
  def setup(player)
  
  @doc "Returns player guess"
  @spec guess(Player.t(any), any) :: {Player.t(any), any}
  def guess(player, guess \\ nil)

end



defimpl Hangman.Player.Action, for: Human do

  def setup(%Human{} = player) do
    # returns {player, choices}
    # where choices is {:guess_letter, "choices_text"} 
    # or {:guess_word, last, "text"}
    Human.setup(player)
  end
  
  def guess(%Human{} = player, guess) do
    Human.guess(player, guess) # returns {player, status} tuple
  end

end


defimpl Hangman.Player.Action, for: Robot do

  def setup(%Robot{} = player) do
    Robot.setup(player) # returns {player, []} tuple
  end
  
  def guess(%Robot{} = player, _guess) do
    Robot.guess(player, nil) # returns {player, status} tuple
  end

end


