defmodule Hangman.Player.Web.Controller do

  @moduledoc """
  Serves as External API into Player functionality.  
  Serves to manage players coming via the web.  

  Responsible for starting a player worker, and via 
  the `Player.Worker.Supervisor` any worker crashes.  

  Forwards player requests to `Player.Worker` and 
  responses back to `Client.Handler`.

  """

  require Logger

  alias Hangman.Player


  @doc """
  Dynamically start a pool of player workers
  """

  @spec start_worker(Player.id, pid) :: :ok
  def start_worker(id, game_pid) do
    {:ok, _player_pid} = 
      Player.Worker.Supervisor.start_child(id, :robot, false, game_pid)

    :ok
  end

  @doc "Issues proceed call to iterate player sequence"

  @spec proceed(Player.id) :: tuple
  def proceed(id) do
    try do
      Player.Worker.proceed(id)
    catch :exit, reason ->
      Logger.info "Caught exit in player controller, reason is #{inspect reason}"
      {:retry, reason}
    end
  end

  @doc "Issues guess request with guess data"
  
  @spec guess(Player.id, tuple | String.t) :: tuple
  def guess(id, data)  when is_tuple(data) or is_binary(data) do
    Player.Worker.guess(id, data)
  end

  @doc "Issues request to stop worker"

  @spec stop_worker(Player.id) :: :ok
  def stop_worker(id) do
    Player.Worker.stop(id)
  end

end
