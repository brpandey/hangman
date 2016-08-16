defmodule Hangman.Player.Worker do

  @moduledoc """
  Simple ExActor GenServer module to implement Player Worker.
  Managed by `Player.Controller`

  The module represents the highest effective player abstraction, 
  and could be thought of as a producer-consumer. 
  It sits in conjunction with other player components, between the Game and
  Reduction engines and the Player.handler - a consumer.

  Behind this GenServer lies the intermediary player components which 
  facilitate player game play.  Such as `Player.Action`, `Player.Human`, 
  `Player.Robot`, `Player.Generic`, `Player.FSM`, `Round`, `Strategy`.

  Internally the ExActor keeps a Player FSM as a state to manage 
  event transitions cleanly.

  The module is abstracted away from the specific type of player to focus mainly on
  feeding the Player FSM and returning the appropriate response to the `Player.Handler`.

  The player interface is very simple: proceed and guess
  """

  use ExActor.GenServer
  require Logger

  alias Hangman.{Player}


  def start_link(args = {player_name, player_type, display, game_pid})
  when is_binary(player_name) and is_atom(player_type) and is_boolean(display) 
  and is_pid(game_pid) and is_tuple(args) do

    Logger.info "Starting Hangman Player Worker #{inspect self}"

    # create the FSM abstraction and then initalize it
    fsm = Player.FSM.new |> Player.FSM.initialize(args) 

    Logger.info "Started Hangman Player Worker, fsm is #{inspect fsm}"

    options = [name: via_tuple(player_name)] #,  debug: [:trace]]
    
    GenServer.start_link(__MODULE__, fsm, options)
  end


  @doc """
  Routine returns game server `pid` from process registry using `gproc`
  If not found, returns `:undefined`
  """
  
  @spec whereis(Player.id) :: pid | :atom
  def whereis(id_key) do
    :gproc.whereis_name({:n, :l, {:player_worker, id_key}})
  end
  

  # Used to register / lookup process in process registry via gproc
  @spec via_tuple(Player.id) :: tuple
  defp via_tuple(id_key) do
    {:via, :gproc, {:n, :l, {:player_worker, id_key}}}
  end


  # The heart of the player server, the proceed request
  defcall proceed, state: fsm do

    Logger.info "Player proceed, state fsm is : #{inspect fsm}"

    # request the next state transition :proceed to player fsm
    {response, fsm} = fsm |> Player.FSM.proceed

    {response, fsm} = case response do
      # if there is no setup data required for the user e.g. [], 
      # as marked during robot guess setup, skip to guess
      {:setup, []} -> fsm |> Player.FSM.guess(nil)
      _ -> {response, fsm}
    end

    set_and_reply(fsm, response)
  end

  
  defcall guess(data), when: is_tuple(data), state: fsm do
    {response, fsm} = fsm |> Player.FSM.guess(data)
    set_and_reply(fsm, response)
  end


  defcall guess(data), when: is_binary(data), state: fsm do
    {response, fsm} = 
      case String.length(data) do
        1 ->
          fsm |> Player.FSM.guess({:guess_letter, data})
        _ ->
          fsm |> Player.FSM.guess({:guess_word, data})
      end
    set_and_reply(fsm, response)
  end

  defcast stop, do: stop_server(:normal)



  @doc """
  Terminate callback.
  """
  
  @callback terminate(term, term) :: :ok
  def terminate(_reason, _state) do
    Logger.info "Terminating Player Worker #{inspect self}"
#   Logger.info "Terminating Player Worker, reason: #{inspect reason}, state: #{inspect state}"
    :ok
  end

end

