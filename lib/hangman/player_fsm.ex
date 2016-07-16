defmodule Hangman.Player.FSM do

  @moduledoc """
  Manages state changes in player fsm
  Heavily relies on Player.Action protocol
  Fsm module simplifies state transitions

  Works for all supported player types
  """

  alias Hangman.Player.{Action}

  use Fsm, initial_state: :new, initial_data: nil

  defstate new do
    defevent initialize(name, type, display, game_pid, event_pid) do

      args = {name, display, game_pid, event_pid}
      action_type = Map.get(Action.Types.mapping, type)
      player = Action.new(action_type, args)

      IO.puts "In state: INIT, action: PROCEED, status: #{status}"

      next_state(:starting, player)
    end    
  end

  defstate starting do
    defevent proceed, data: player do

      {player, status} = player 
      |> Action.start 
      |> Action.guess

      IO.puts "In state: STARTING, action: PROCEED, status: #{status}"

      next_state(:guessing, player)
    end    
  end

  
  # In guessing state, what if we get a game won or game lost

  defstate guessing do
    defevent proceed, data: player do

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

  
  defstate stopped do
    defevent proceed, data: player do

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
  
  defstate exit do
    defevent proceed, data: player do
      #Games Over
      IO.puts "In state: EXIT, action: PROCEED, status: #{player.round.status}"
      next_state(:exit, player)

    end
  end

end
