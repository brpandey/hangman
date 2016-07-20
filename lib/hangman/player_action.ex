alias Hangman.Player.{Human, Robot, Generic}

@moduledoc """
Protocol to implement player dynamic dispatch 
functionality for various player types

## NEEDS TO BE REWRITTEN BELOW

Module for to represent the highest player abstraction.

The goal of the player is to maximize our winning chances in conjunction
with the player strategy against the 'implicit' other player, the `game server`.

Player functionality handles choosing letters, guessing letters and words.

In `Hangman` we have two players.  One explict - the one guessing, the other
implicit, 'the game', 'the user tracking the penalties', or 'the stumper
stumping the guesser with hard words'.  In this instance, the `Player` is
merely the user making and choosing the guess selections.  

The `human` player is given the choice of the top letter choices to choose
from and is able to make an interactive guess.  The `robot` player is reliant
on the game strategy to automatically self select the best guess.

Player is one of seven modules that drive the game play mechanics, the others 
being `Player.Human`, `Player.Robot`, `Player.Generic`, `Player.FSM`, `Round`, `Strategy`.

Player encapsulates the data used along with Strategy data. `Round` functionality
extends the scope of the player to handle the actual game round details.

NOTE: Should a player submit a secret hangman word that does not actually
reside in the `Dictionary.Cache`, the game will currently be prematurely 
aborted.
"""

defmodule Hangman.Player.Types do

  def mapping do
    %{
      :human => %Hangman.Player.Human{}, 
      :robot => %Hangman.Player.Robot{}
    }
  end
  
end

defprotocol Hangman.Player.Action do

  @doc "Create new player"
  def new(player, args)

  @doc "Start new game player action"
  def start(player)

  @doc "Sets up each action state"
  def setup(player)
  
  @doc "Returns player guess"
  def guess(player, guess \\ nil)

  @doc "Returns the correct player transition at the game end"
  def transition(player)
end


defimpl Hangman.Player.Action, for: Human do
  def new(%Human{} = player, {name, display, game_pid, event_pid}) when is_binary(name) 
      and is_bool(display) and is_pid(game_pid) and is_pid(event_pid) do

    round = Generic.new(name, game_pid, event_pid)
    %Human{display: display, round: round}
  end

  def start(%Human{} = player) do
    {round, strategy} = Generic.start(player.round, player.type)
    %Human{ player | round: round, strategy: strategy }
  end

  def setup(%Human{} = player) do
    Human.setup(player) # returns {player, choices}
    # where choices is {:guess_letter, "choices_text"} or {:guess_word, last, "text"}
  end
  
  def guess(%Human{} = player, guess) do
    Human.guess(player, guess) # returns {player, status} tuple
  end

  def transition(%Human{} = player) do
    {round, status} = Generic.transition(player.round)
    player = Kernel.put_in(player.round, round)

    {player, status}
  end
end


defimpl Hangman.Player.Action, for: Robot do

  def new(%Human{} = player, {name, display, game_pid, event_pid})
  when is_binary(name) and is_bool(display) and is_pid(game_pid)
  and is_pid(event_pid) do

    round = Generic.new(name, game_pid, event_pid)    
    %Robot{display: display, round: round}
  end

  def start(%Robot{} = player) do
    {round, strategy} = Generic.start(player.round, player.type)
    %Robot{player | round: round, strategy: strategy}
  end

  def setup(%Robot{} = player) do
    Robot.setup(player) # returns {player, []} tuple
  end
  
  def guess(%Robot{} = player, _guess) do
    Robot.guess(player) # returns {player, status} tuple
  end

  def transition(%Robot{} = player) do
    {round, status} = Generic.transition(player.round)
    player = Kernel.put_in(player.round, round)
    
    {player, status}
  end
end
