defmodule Hangman.Player do

  # FIRST implement Player as just a module
  # THEN implement as a GenServer
  
  # use GenServer
  # Assume player is its own gen server process e.g. using ExActor

  @moduledoc """
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


  ############## CODE BELOW DOES NOT WORK ########################

  ### WILL REPLACE #######
  def run do

    player = Player.new
    fsm = Player.FSM.new

    for {action, p} <- Stream.cycle([{&Player.FSM.proceed, player}]) do
      
      case action.(p) do
        {:ok, fsm} -> player = Player.FSM.data(fsm)
        {:exit, _} -> System.halt  # Should really be GenServer.stop
      end

    end
  end

end

