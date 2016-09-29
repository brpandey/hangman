defmodule Hangman.Player do

  @moduledoc """
  Defines Player id and key

  Provides Player generic routine implementations.  

  For polymorphic routines, delegates to Player.Action protocol.

  Player is the common DNA unifying all players.

  The `Player.Action` protocol
  implement the specialized functionality of the player types
  """

  alias Hangman.{Player, Round, Letter.Strategy}
  
  # The Player ID needs to be unique during multiple concurrent game play
  # Async testing of hangman games should use different player ids

  @type id :: String.t | {id :: String.t, shard_no :: pos_integer}
  @type key :: {id :: String.t, player_pid :: pid} # Used as game key


  @doc "Create new player"
  def new({name, type, display, game_pid})
  when (is_binary(name) or is_tuple(name)) and
  is_boolean(display) and is_pid(game_pid) and is_atom(type) do

    player = Map.get(Player.Types.types, type)
    round = Round.new(name, game_pid)

    %{player | display: display, round: round}
  end


  @doc "Begin new game player action"
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
  def transition(player) do
    round = player.round

    round = Round.transition(round)
    status = Round.status(round)
    player = Kernel.put_in(player.round, round)

    {player, status}
  end



end


