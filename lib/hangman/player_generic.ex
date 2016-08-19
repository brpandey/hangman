defmodule Hangman.Player.Generic do
  
  @moduledoc """
  Provides Generic player routine implementations used by
  the Player Action protocol
  """
  
  alias Hangman.{Round, Letter.Strategy}

  def new(name, game_pid) when is_binary(name) and is_pid(game_pid) do
    %Round{ id: name, pid: nil, game_pid: game_pid }
  end

  def begin(%Round{} = round, type) do
    round = Round.init(round)
    strategy = Strategy.new(type)

    case Round.status(round) do
      {:finished, _text} -> {round, strategy, :finished}
      _ -> {round, strategy, :start}
    end
  end

  def transition(%Round{} = round) do
    round = Round.transition(round)
    status = Round.status(round)

    {round, status}
  end

end
