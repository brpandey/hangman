defmodule Hangman.Player.Controller do

  @moduledoc """
  Serves as External API into Player functionality.  
  Serves to manage players.  

  Responsible for starting a player worker, and via gproc, handles
  any worker crashes.  

  Forwards player requests to `Player.Worker` and 
  responses back to `Client.Handler`.
  """

  use ExActor.GenServer, export: :hangman_player_controller
  require Logger

  alias Hangman.Player

  @doc """
  GenServer start link wrapper function
  """
  
  defstart start_link do 
    Logger.info "Starting Hangman Player Controller Server #{inspect self}"
    initial_state(nil)
  end


  @docp "Start dynamic `player` child `worker`"
  
  defcast start_worker(name, type, display, game_pid), 
  when: is_binary(name) and is_atom(type) and is_boolean(display) 
  and is_pid(game_pid), state: _state do
    {:ok, player_pid} = 
      Player.Worker.Supervisor.start_child(name, type, display, game_pid)

    #link to player process
    Process.link(player_pid)

    noreply()
  end

  defcall proceed(id), state: _state do
    player_pid =  get_worker_pid(id)
    response = player_pid |> Player.Worker.proceed

    reply(response)
  end

  defcall guess(id, data), when: is_tuple(data) or is_binary(data), state: _state do
    player_pid =  get_worker_pid(id)
    response = player_pid |> Player.Worker.guess(data)
    
    reply(response)
  end

  defcast stop_worker(id), state: _state do
    player_pid =  get_worker_pid(id)
    player_pid |> Player.Worker.stop

    noreply()
  end

  
  @docp """
  Checks registry cache for `Player.Worker` pid given unique id, returns cached `pid` or
  if not found checks again. Handles race conditions
  """
  
  @spec get_worker_pid(Player.id) :: pid
  defp get_worker_pid(player_name) do    
    pid = 
      case Player.Worker.whereis(player_name) do
        :undefined ->
          GenServer.call(:hangman_player_controller, {:get_worker, player_name})
        pid -> pid
      end

    Process.link(pid)

    pid
  end
  
  @docp """
  GenServer callback to initialize server process
  """

  #@callback init(term) :: {}
  def init(_) do
  
    # Trap client exits
    Process.flag(:trap_exit, true)
    {:ok, nil} 

  end
  
  @docp """
  GenServer callback to retrieve worker pid
  """
  
  #@callback handle_call({:atom, Player.id}, {}, term) :: {}
  def handle_call({:get_worker, player_name}, _from, state) do
    
    #Check the registry again for the pid -- safeguard against race condition
    pid = 
      case Player.Worker.whereis(player_name) do
        :undefined -> raise "Player Controller, no player worker found"
        pid -> pid
      end
    
    {:reply, pid, state}
  end


  def handle_info({:EXIT, pid, :normal} = msg, state) do
    Logger.debug "In Process.Controller handle info, received EXIT normal msg: #{inspect msg}, from #{pid}"

    Logger.debug("{:EXIT, _, :normal}, #{inspect state}")

    { :noreply, state }
  end


  def handle_info({:EXIT, pid, _reason} = msg, state) do
    Logger.debug "In Process.Controller handle info, received EXIT abnormal msg: #{inspect msg}, from #{pid}"
    
    Logger.debug("{:EXIT, _, abnormal}, #{inspect state}")
    { :noreply, state }
  end


  @doc """
  Terminate callback.
  """
  
  @callback terminate(term, term) :: :ok
  def terminate(reason, _state) do
    Logger.info "Terminating Player Controller, #{inspect self}, reason: #{inspect reason}"
    :ok
  end


end
