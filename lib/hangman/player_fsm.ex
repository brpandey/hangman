defmodule Hangman.Player.FSM do

  @moduledoc """
  Manages state changes in player fsm

  Heavily relies on Player.Action protocol

  Feels much simpler with sasa1977's FSM module
  """

  alias Hangman.Player.{Action}

  use Fsm, initial_state: :stopped, initial_data: nil
  
  defstate stopped do
    defevent proceed(player) do

      {player, status} = Action.transition(player)

      IO.puts "In state: STOPPED, action: PROCEED, status: #{status}"

      case status do
        {:game_start, _text} -> 
          next_state(:starting, player)

        {:games_over, _text} -> 
          next_state(:exit, player)
      end
    end
  end
  

  defstate starting do
    defevent proceed(player) do

      {player, status} = player 
      |> Action.start 
      |> Action.guess

      IO.puts "In state: STARTING, action: PROCEED, status: #{status}"

      next_state(:guessing, player)
    end    
  end
  
  # In guessing state, what if we get a game won or game lost

  defstate guessing do
    defevent proceed(player) do
      {player, status} = player |> Action.guess

      IO.puts "In state: GUESSING, action: PROCEED, status: #{status}"

      # check if we get game won or game lost
      case status do
        {status, _} when status in [:game_won, :game_lost] -> 
          next_state(:stopped, player)

        {:game_keep_guessing, _} ->
          next_state(:guessing, player)
      end
    end
  end

  
  defstate exit do
    defevent proceed(player) do
      #Games Over
      IO.puts "In state: EXIT, action: PROCEED, status: #{player.round.status}"
      next_state(:exit, player)

    end
  end

end
