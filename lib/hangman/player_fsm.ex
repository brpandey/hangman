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

  States are `initial`, `begin`, `setup`, `action`, `transit`, `exit`
  """

  alias Hangman.Player.{Action, Types}

  require Logger

  use Fsm, initial_state: :initial, initial_data: nil

  defstate initial do
    defevent initialize(args = {_name, type, _display, _game_pid}) do

      action_type = Map.get(Types.mapping, type)
      args = args |> Tuple.delete_at(1) # remove the type field
      player = Action.new(action_type, args)

      next_state(:begin, player)
    end
  end


  defstate begin do
    defevent proceed, data: player do

      {player, code} = player |> Action.begin 

      case code do
        :start -> respond({:begin, "fsm begin"}, :setup, player)
        :finished -> respond({:begin, "going to fsm exit"}, :exit, player)
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
        {code, text} when code in [:won, :lost] -> 
          respond({:action, text}, :transit, player)
        {:guessing, text} ->
          respond({:action, text}, :setup, player)
      end
    end
  end

  
  defstate transit do
    defevent proceed, data: player do

      {player, status} = player |> Action.transition

      Logger.debug "FSM transit: player is #{inspect player}"

      case status do
        {:start, text} -> 
          respond({:transit, text}, :begin, player)
        {:finished, text} -> 
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
