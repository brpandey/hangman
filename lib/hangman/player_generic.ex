defmodule Hangman.Player.Generic do
  
  @moduledoc """
  Provides Generic player routine implementations used by
  the Player.Action protocol.  Fills in the `Player` gaps
  before the specific Action implementation kicks in.

  Generic is the common DNA unifying all players and `Action`
  represents the specialized components of the player types
  which provide its willful spark.
  """
  
  alias Hangman.{Player, Round, Letter.Strategy}

  @spec new(Player.id, pid) :: Round.t
  def new(name, game_pid) when 
  (is_binary(name) or is_tuple(name)) and is_pid(game_pid) do
    %Round{ id: name, pid: nil, game_pid: game_pid }
  end

  @spec begin(Round.t, atom) :: tuple
  def begin(%Round{} = round, type) do
    round = Round.init(round)
    strategy = Strategy.new(type)

    case Round.status(round) do
      {:finished, _text} -> {round, strategy, :finished}
      _ -> {round, strategy, :start}
    end
  end

  @spec transition(Round.t) :: tuple
  def transition(%Round{} = round) do
    round = Round.transition(round)
    status = Round.status(round)

    {round, status}
  end

end
