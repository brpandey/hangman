defmodule Hangman.Player.FSM do

  @moduledoc """
  Module implements a non-process player fsm
  which handles managing the state of types implemented
  through the Player Action protocol.  

  The FSM is not coupled at all to the
  specific player type but the Action Protocol, which
  provides for succinct code along with the already succinct
  design of the Fsm module code.

  Works for all supported player types
  """

  alias Hangman.Player.{Action, Types}

  use Fsm, initial_state: :init, initial_data: nil

  defstate init do
    defevent initialize(name, type, display, game_pid, event_pid) do
      args = {name, display, game_pid, event_pid}
      action_type = Map.get(Types.mapping, type)

      player = Action.new(action_type, args)
      next_state(:start, player)
    end
  end


  defstate start do
    defevent proceed, data: player do
      {player, status} = player |> Action.start 
      respond({:start, status}, :setup, player)
    end    
  end

  
  defstate setup do
    defevent proceed, data: player do
      {player, status} = player |> Action.setup

      new_state = :action

      case status do
        [] -> respond({:setup, []}, 
                      new_state, player)
        _ ->  respond({:setup, [display: player.display, status: status]}, 
                      new_state, player)
      end
    end
  end


  defstate action do
    defevent guess(data \\ nil), data: player do

      {player, status} = player |> Action.guess(data)

      # check if we get game won or game lost
      case status do
        {code, text} when code in [:game_won, :game_lost] -> 
          respond({:action, text}, :stop, player)
        {:game_keep_guessing, text} ->
          respond({:action, text}, :action, player)
      end
    end
  end

  
  defstate stop do
    defevent proceed, data: player do

      {player, status} = player |> Action.transition

      case status do
        {:game_start, text} -> 
          respond({:stop, text}, :start, player)
        {:games_over, text} -> 
          respond({:stop, text}, :exit, player)
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
