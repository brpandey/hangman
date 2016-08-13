defmodule Hangman.Player.Generic do
  
  @moduledoc """
  Provides Generic player routine implementations used by
  the Player Action protocol
  """
  
  alias Hangman.{Round, Letter.Strategy}

  def init(name, game_pid) when is_binary(name) and is_pid(game_pid) do
    %Round{ id: name, pid: self(), game_pid: game_pid }
  end

  def start(%Round{} = round, type) do
    round = Round.start(round)
    strategy = Strategy.new(type)

    case Round.status(round) do
      {:game_start, _text} -> {round, strategy, :game_start}
      {:games_over, _text} -> {round, strategy, :games_over}
    end

  end

  def transition(%Round{} = round) do
    round = Round.transition(round)
    status = Round.status(round)

    {round, status}
  end

end
