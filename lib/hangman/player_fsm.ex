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

  require Logger

  use Fsm, initial_state: :init, initial_data: nil

  defstate init do
    defevent initialize(args = {_name, type, _display, _game_pid}) do

      action_type = Map.get(Types.mapping, type)
      args = args |> Tuple.delete_at(1) # remove the type field
      player = Action.new(action_type, args)

      next_state(:start, player)
    end
  end


  defstate start do
    defevent proceed, data: player do

      {player, code} = player |> Action.start 

      case code do
        :game_start -> respond({:start, "fsm start"}, :setup, player)
        :games_over -> respond({:start, "going to fsm exit"}, :exit, player)
      end
    end
  end

  
  defstate setup do
    defevent proceed, data: player do

      {player, status} = player |> Action.setup

      Logger.debug "FSM setup: player is #{inspect player}"

      case status do
        [] -> respond({:setup, []}, 
                      :action, player)
        _ ->  respond({:setup, [display: player.display, status: status]}, 
                      :action, player)
      end
    end
  end


  defstate action do
    defevent guess(data), data: player do

      {player, status} = player |> Action.guess(data)

      Logger.debug "FSM action: player is #{inspect player}"

      # check if we get game won or game lost
      case status do
        {code, text} when code in [:game_won, :game_lost] -> 
          respond({:action, text}, :transit, player)
        {:game_keep_guessing, text} ->
          respond({:action, text}, :setup, player)
      end
    end
  end

  
  defstate transit do
    defevent proceed, data: player do

      {player, status} = player |> Action.transition

      Logger.debug "FSM transit: player is #{inspect player}"

      case status do
        {:game_start, text} -> 
          respond({:transit, text}, :start, player)
        {:games_over, text} -> 
          respond({:transit, text}, :exit, player)
      end
    end
  end

  
  defstate exit do
    defevent proceed, data: player do

      Logger.debug "FSM exit: player is #{inspect player}"

      #Games Over
      respond({:exit, player.round.status_text}, :exit, player)

    end
  end

  # called for undefined state/event mapping when inside any state
  defevent _, do: raise "Player FSM doesn't support requested state:event mapping."

end
