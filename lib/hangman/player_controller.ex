defmodule Hangman.Player.Controller do
  use GenServer

  @moduledoc """
  Serves as External API into Player functionality.  
  Serves to manage players.  

  Responsible for starting a player worker, and via gproc, handles
  any worker crashes.  

  Forwards player requests to `Player.Worker` and 
  responses back to `Client.Handler`.
  """

  require Logger

  alias Hangman.Player

  @name :hangman_player_controller

  @doc """
  GenServer start link wrapper function
  """
  
  def start_link(), do: GenServer.start_link(__MODULE__, nil, [name: @name])

  def register(pid), do: GenServer.cast(@name, {:register, pid})

  def start_worker(name, type, display, game_pid) when is_binary(name) and 
      is_atom(type) and is_boolean(display) and is_pid(game_pid) do
    GenServer.cast(@name, {:start_worker, name, type, display, game_pid})
  end

  def proceed(id), do: GenServer.call(@name, {:proceed, id})

  def guess(id, data) when is_tuple(data) or is_binary(data) do    
    GenServer.call(@name, {:guess, id, data})
  end

  def stop_worker(id), do: GenServer.cast(@name, {:stop_worker, id})

  
  
  @docp """
  GenServer callback to initialize server process
  """

  #@callback init(term) :: {}
  def init(_) do
    Logger.info "Starting Hangman Player Controller Server #{inspect self}"
    {:ok, nil} 
  end

  def handle_cast({:start_worker, name, type, display, game_pid}, state) do
    {:ok, _player_pid} = 
      Player.Worker.Supervisor.start_child(name, type, display, game_pid)

    {:noreply, state}
  end

  def handle_cast({:register, pid}, state) when is_pid(pid) do
    Process.monitor(pid)
    {:noreply, state}
  end


  def handle_cast({:stop_worker, id}, state) do
    player_pid =  get_worker_pid(id)
    player_pid |> Player.Worker.stop

    {:noreply, state}
  end

  def handle_call({:proceed, id}, _from, state) do
    player_pid =  get_worker_pid(id)
    response = player_pid |> Player.Worker.proceed

    {:reply, response, state}
  end

  
  def handle_call({:guess, id, data}, _from, state) do
    player_pid =  get_worker_pid(id)
    response = player_pid |> Player.Worker.guess(data)
    
    {:reply, response, state}
  end


  def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
    Logger.debug "In Process.Controller handle info, received DOWN normal msg, from #{inspect pid}"

    Logger.debug("{:EXIT, _, :normal}, #{inspect state}")

    { :noreply, state }
  end

  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    Logger.debug "In Process.Controller handle info, received DOWN abnormal msg, from #{inspect pid}"
    
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


  @docp """
  Checks registry cache for `Player.Worker` pid given unique id, returns cached `pid`
  """
  
  @spec get_worker_pid(Player.id) :: pid
  defp get_worker_pid(player_name) do    

    pid =
    case Player.Worker.whereis(player_name) do
      :undefined -> raise "Unable to find worker pid"
      pid -> pid
    end

    pid
  end


end
