defmodule Hangman.Player.FSM do
  @moduledoc """
  Module implements a non-process player fsm
  which handles managing the state of types implemented
  through Player and the Player Action protocol.  

  FSM provides a state machine wrapper over the `Player`

  The FSM is not coupled at all to the
  specific player type but the generic Player
  which relies on the Action Protocol, which
  provides for succinct code along with the already succinct
  design of the Fsm module code.

  Works for all supported player types

  States are `initial`, `begin`, `setup`, `action`, `transit`, `exit`

  The event `proceed` transitions between states, when we are not issuing
  a `guess` or `initialize` event.

  Here are the state transition flows:

  A) initial -> begin
  B) begin -> setup | exit
  C) setup -> action
  D) action -> transit | setup
  E) transit -> begin | exit
  F) exit -> exit

  Basically upon leaving the initial state, we transition to begin.
  From there we make the determination of  whether we should proceed on to setup the guess
  state or terminate early and exit.

  If the game was recently just aborted and we are done with playing any more games -> we exit.

  Once we are in the setup state it is obvious that our next step is to the action state.
  Here we can try out our new guess (either selected or auto-generated)

  From action state we either circle back to setup state to generate the new word set state and 
  overall guess state and possibly to collect the next user guess.  Else, we have either 
  won or lost the game and can confidently move to the transit state.

  The transit state indicates that we are in transition having a single game over.
  Either we proceed to start a new game and head to begin or we've already finished 
  all games and happily head to the exit state.

  Ultimately the specific Flow or CLI `Handler`, when in exit state terminates the FSM loop
  """

  use Fsm, initial_state: :initial, initial_data: nil
  alias Hangman.Player
  require Logger

  defstate initial do
    defevent initialize(args) do
      player = Player.new(args)
      next_state(:begin, player)
    end
  end

  defstate begin do
    defevent proceed, data: player do
      {player, code} = player |> Player.begin
      case code do
        :start -> respond({:begin, "fsm begin"}, :setup, player)
        :finished -> respond({:begin, "going to fsm exit"}, :exit, player)
      end
    end
  end
  
  defstate setup do
    defevent proceed, data: player do
      {player, status} = player |> Player.setup
  #    Logger.debug "FSM setup: player is #{inspect player}"
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
      {player, status} = player |> Player.guess(data)
      _ = Logger.debug "FSM action: player is #{inspect player}"

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
      {player, status} = player |> Player.transition
#      _ = Logger.debug "FSM transit: player is #{inspect player}"

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
      _ = Logger.debug "FSM exit: player is #{inspect player}"

      #Games Over
      respond({:exit, player.round.status_text}, :exit, player)
    end
  end

  # called for undefined state/event mapping when inside any state
  defevent _, do: raise "Player FSM doesn't support requested state:event mapping."

end
