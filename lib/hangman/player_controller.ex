defmodule Hangman.Player.Controller do
  use GenServer

  @moduledoc """
  Serves as External API into Player functionality.  
  Serves to manage players.  

  Responsible for starting a player worker, and via gproc, handles
  any worker crashes.  

  Forwards player requests to `Player.Worker` and 
  responses back to `Client.Handler`.

  NOTE: This doesn't need to be a GenServer process right now
  """

  require Logger

  alias Hangman.Player

  @name :hangman_player_controller

  @doc """
  GenServer start link wrapper function
  """
  
  def start_link(), do: GenServer.start_link(__MODULE__, nil, [name: @name])

  def start_worker(name, type, display, game_pid) when is_binary(name) and 
      is_atom(type) and is_boolean(display) and is_pid(game_pid) do
    GenServer.call(@name, {:start_worker, name, type, display, game_pid})
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

  def handle_cast({:stop_worker, id}, state) do
    Player.Worker.stop(id)

    {:noreply, state}
  end

  def handle_call({:start_worker, name, type, display, game_pid}, _from, state) do
    {:ok, player_pid} = 
      Player.Worker.Supervisor.start_child(name, type, display, game_pid)

    {:reply, player_pid, state}
  end

  def handle_call({:proceed, id}, _from, state) do    
    response = do_proceed(id)
    {:reply, response, state}
  end
  
  def handle_call({:guess, id, data}, _from, state) do
    response = Player.Worker.guess(id, data)
  
    {:reply, response, state}
  end


  @doc """
  Terminate callback.
  """
  
  @callback terminate(term, term) :: :ok
  def terminate(reason, _state) do
    Logger.info "Terminating Player Controller, #{inspect self}, reason: #{inspect reason}"
    :ok
  end


  defp do_proceed(id) do
    try do
      Player.Worker.proceed(id)
    catch :exit, reason ->
      Logger.info "Caught exit in player controller, reason is #{inspect reason}"
      Process.sleep(2000) # Stop gap for now for no proc error by gproc
      {:retry, reason}
    end
  end

end
