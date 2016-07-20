defmodule Hangman.Player do

  @moduledoc """
  Simple server module to implement Player

  Keeps Player FSM internally as state
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
    {response, fsm} = Player.FSM.proceed(fsm)

    case response do
      # if there is no setup data required for the user e.g. robot, 
      # skip to next proceed
      {:guess_setup, []} -> {response, fsm} = Player.FSM.proceed(fsm)
      _ -> ""
    end

    set_and_reply(fsm, response)
  end


  # The heart of the player server, this proceed request only called
  # after a guess_setup
  defcall proceed(guess), state: fsm do

    # send the next proceed event to the player fsm
    {response, fsm} = fsm |> Player.FSM.proceed(guess)

    set_and_reply(fsm, response)
  end
  
  defcast stop, do: stop_server(:normal)

end

