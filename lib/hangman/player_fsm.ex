defmodule Hangman.Player.FSM do

  @moduledoc """
  Manages state changes in player fsm
  Heavily relies on Player.Action protocol
  Fsm module simplifies state transitions

  Works for all supported player types
  """

  alias Hangman.Player.{Action, Types}

  use Fsm, initial_state: :new, initial_data: nil


  defstate new do
    defevent initialize(name, type, display, game_pid, event_pid) do
      args = {name, display, game_pid, event_pid}
      action_type = Map.get(Types.mapping, type)

      player = Action.new(action_type, args)

      response = {:new, "In state: new, action: initialize"}

      respond(response, :starting, player)
    end    
  end


  defstate starting do
    defevent proceed, data: player do
      {player, status} = player |> Action.start 
      respond({:starting, status}, :guess_setup, player)
    end    
  end

  
  # In guessing state, what if we get a game won or game lost

  defstate guess_setup do
    defevent proceed, data: player do
      {player, status} = player |> Action.setup

      new_state = :guess_action

      case status do
        [] -> respond({:guess_setup, []}, 
                      new_state, player)
        _ ->  respond({:guess_setup, {player.display, status}}, 
                      new_state, player)
      end
    end
  end


  defstate guess_action do
    defevent proceed(data // nil), data: player do

      {player, status} = player |> Action.guess(data)

      # check if we get game won or game lost
      case status do
        {code, text} when code in [:game_won, :game_lost] -> 
          respond({:guess_action, text}, :stopped, player)
        {:game_keep_guessing, text} ->
          respond({:guess_action, text}, :guess_action, player)
      end
    end
  end

  
  defstate stopped do
    defevent proceed, data: player do

      {player, status} = player |> Action.transition

      case status do
        {:game_start, text} -> 
          respond({:stopped, text}, :starting, player)
        {:games_over, text} -> 
          respond({:stopped, text}, :exit, player)
      end
    end
  end

  
  defstate exit do
    defevent proceed, data: player do

      #Games Over
      respond({:exit, player.round.status_text}, :exit, player)

    end
  end

end
