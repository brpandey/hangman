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
  defcall proceed(guess \\ nil), state: fsm do

    # request the next state transition :proceed to player fsm

    {response, fsm} = 
      case guess do # permit proceeding with or w/o a guess value
        nil -> fsm |> Player.FSM.proceed
        _ -> fsm |> Player.FSM.proceed(guess)
      end

    case response do
      # if there is no setup data required for the user e.g. [], 
      # as marked during robot guess setup, skip to next proceed
      {:setup, []} -> {response, fsm} = fsm |> Player.FSM.proceed
      _ -> ""
    end

    set_and_reply(fsm, response)
  end

  defcast stop, do: stop_server(:normal)

end

