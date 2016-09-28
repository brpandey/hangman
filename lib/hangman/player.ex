defmodule Hangman.Player do

  @moduledoc """
  Defines Player types

  Provides Player generic routine implementations.  

  For polymorphic  routines, forwards request
  to Player.Action protocol.

  Player is the common DNA unifying all players and `Action` protocol
  implement the specialized components of the player types
  """

  alias Hangman.{Player, Round, Letter.Strategy}
  
  # The Player ID needs to be unique during multiple concurrent game play
  # Async testing of hangman games should use different player ids

  @type id :: String.t | {id :: String.t, shard_no :: pos_integer}
  @type key :: {id :: String.t, player_pid :: pid} # Used as game key

  # Defines the generic player type. Note this is a supertype of the 
  # player specific types by just the type field

  @type t :: %{
    type: atom,
    display: boolean,
    round: nil | Round.t,
    strategy: nil | Strategy.t
  }


  def human, do: :human
  def robot, do: :robot

  def types do
    %{
      :human => %Hangman.Action.Human{}, 
      :robot => %Hangman.Action.Robot{}
    }
  end


  @doc "Create new player"
  @spec new(tuple) :: Player.t
  def new({name, type, display, game_pid})
  when (is_binary(name) or is_tuple(name)) and
  is_boolean(display) and is_pid(game_pid) and is_atom(type) do

    player = Map.get(Player.types, type)
    round = Round.new(name, game_pid)

    %{player | display: display, round: round}
  end


  @doc "Begin new game player action"
  @spec begin(Player.t) :: {Player.t, :start | :finished}
  def begin(player) do

    round = player.round
    type = player.type

    round = Round.init(round)
    strategy = Strategy.new(type)

    code = 
      case Round.status(round) do
        {:finished, _text} -> :finished
        _ -> :start
      end

    player = %{ player | round: round, strategy: strategy }

    {player, code}
  end


  # Forward to polymorphic functions

  @doc "Sets up each action state"
  def setup(player) do
    Player.Action.setup(player)
  end
  
  @doc "Returns player guess"
  def guess(player, guess \\ nil) do
    Player.Action.guess(player, guess)
  end



  @doc "Returns the correct player transition at the game end"
  @spec transition(Player.t) :: {Player.t, tuple}
  def transition(player) do
    round = player.round

    round = Round.transition(round)
    status = Round.status(round)
    player = Kernel.put_in(player.round, round)

    {player, status}
  end



end


