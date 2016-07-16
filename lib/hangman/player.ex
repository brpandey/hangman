defmodule Hangman.Player do

  @moduledoc """
  Simple server module to implement player
  """

  use ExActor.GenServer

  @name __MODULE__

  defstart start_link(args = {player_name, player_type, display, game_pid, event_pid})
  when is_binary(player_name) and is_atom(player_type) 
  and is_bool(display) and is_pid(game_pid) and is_pid(event_pid) do

    Logger.info "Starting Hangman Player Server"

    # create the FSM abstraction and then initalize it
    fsm = Player.FSM.new |> Player.FSM.initialize(args)

    initial_state(fsm)
  end


  # The heart of the player server, the proceed request
  defcall proceed, state: fsm do

    # request the next state transition :proceed to player fsm
    fsm = Player.FSM.proceed(fsm)

    # get the fsm data
    data = Player.FSM.data(fsm)

    set_and_reply(fsm, data)
  end
  
  defcast stop, do: stop_server(:normal)


end

