defmodule Hangman.Player.Generic do
  
  @moduledoc """
  Provides Generic player routine implementations used by
  the Player Action protocol
  """
  
  def start(%Round{} = round, type) do
    round = Round.start(round)
    strategy = Strategy.new(type)

    {round, strategy}
  end

  def transition(%Round{} = round) do
    round = Round.transition(round)
    status = Round.status(round)

    {round, status}
  end

end
