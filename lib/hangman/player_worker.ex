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

  use GenServer
  require Logger

  alias Hangman.{Player}


  # CLIENT API #

  def start_link(args = {player_name, player_type, display, game_pid})
  when is_binary(player_name) and is_atom(player_type) and is_boolean(display) 
  and is_pid(game_pid) and is_tuple(args) do

    options = [name: via_tuple(player_name)] #,  debug: [:trace]]
    
    GenServer.start_link(__MODULE__, args, options)
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
  def proceed(pid), do: GenServer.call(pid, :proceed)

  def guess(pid, data) when is_tuple(data) do
    GenServer.call(pid, {:guess, data})
  end

  def guess(pid, data) when is_binary(data) do
    GenServer.call(pid, {:guess, data})
  end
  
  def stop(pid) do
    GenServer.call(pid, :stop)
  end



  #@callback init(Registry.t) :: tuple
  def init(args) do


    Player.Controller.register(self)

    controller_pid = Process.whereis(:hangman_player_controller)

    Logger.info "Registered self: #{inspect self} with controller: #{inspect controller_pid}"

    # create the FSM abstraction and then initalize it
    fsm = Player.FSM.new |> Player.FSM.initialize(args) 

    Logger.info "Started Player Worker #{inspect self}"
    Logger.info "Started Player Worker, fsm is #{inspect fsm}"

    {:ok, fsm}
  end


  def handle_call(:proceed, _from, fsm) do

    Logger.info "Player proceed, state fsm is : #{inspect fsm}"

    # request the next state transition :proceed to player fsm
    {response, fsm} = fsm |> Player.FSM.proceed

    {response, fsm} = case response do
      # if there is no setup data required for the user e.g. [], 
      # as marked during robot guess setup, skip to guess
      {:setup, []} -> fsm |> Player.FSM.guess(nil)
      _ -> {response, fsm}
    end

    {:reply, response, fsm}
  end


  def handle_call({:guess, data}, _from, fsm) when is_binary(data) do
    {response, fsm} = 
      case String.length(data) do
        1 ->
          fsm |> Player.FSM.guess({:guess_letter, data})
        _ ->
          fsm |> Player.FSM.guess({:guess_word, data})
      end
    
    {:reply, response, fsm}
  end

  
  def handle_call({:guess, data}, _from, fsm) when is_tuple(data) do
    {response, fsm} = fsm |> Player.FSM.guess(data)
    {:reply, response, fsm}
  end

  @docp """
  Stops the server in a normal graceful way
  """
  
#  @callback handle_call(:atom, tuple, any) :: tuple
  def handle_call(:stop, _from, state), do: { :stop, :normal, :ok, state }


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

