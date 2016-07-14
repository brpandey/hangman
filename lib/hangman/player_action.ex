alias Hangman.Player.{Human, Robot, Generic}

@moduledoc """
Protocol to implement player dynamic dispatch 
functionality for various player types
"""

defprotocol Hangman.Player.Action do

  @doc "Start new game player action"
  def start(player)
  
  @doc "Returns player guess"
  def guess(player)

  @doc "Returns the correct player transition at the game end"
  def transition(player)
end


defimpl Hangman.Player.Action, for: Human do

  def start(%Human{} = player) do
    {round, strategy} = Generic.start(player.round, player.type)
    %Human{ player | round: round, strategy: strategy }
  end
  
  def guess(%Human{} = player) do
    Human.guess(player) # returns {player, status} tuple
  end

  def transition(%Human{} = player) do
    {round, status} = Generic.transition(player.round)
    player = Kernel.put_in(player.round, round)

    {player, status}
  end
  
end


defimpl Hangman.Player.Action, for: Robot do

  def start(%Robot{} = player) do
    {round, strategy} = Generic.start(player.round, player.type)
    %Robot{player | round: round, strategy: strategy}
  end
  
  def guess(%Robot{} = player) do
    Robot.guess(player) # returns {player, status} tuple
  end

  def transition(%Robot{} = player) do
    {round, status} = Generic.transition(player.round)
    player = Kernel.put_in(player.round, round)
    
    {player, status}
  end
end
