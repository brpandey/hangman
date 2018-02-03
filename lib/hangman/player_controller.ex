defmodule Hangman.Player.Controller do
  @moduledoc """
  Serves as External API into Player functionality.  
  Serves to manage players.  

  Responsible for starting a player worker, and via 
  the `Player.Worker.Supervisor` any worker crashes.  

  Forwards player requests to `Player.Worker` and 
  responses back to the relevant `Handler`, either CLI or Web.

  The `Player` sandwich shows the ingredient layers of the player:

  cli_handler | web_handler (the player clients) 
  --------
  player controller (a proxy module, providing a single player interface)
  --------
  player worker supervisor (dynamically starts children and handles abnormal crashes)
  --------
  player worker (issues requests to fsm)
  --------
  player fsm (fsm wrapper for action protocol)
  --------
  player action (handles dynamic dispatch based on player types)
  --------
  action human | action robot (specific types implemented)
  --------
  round | strategy (handles game playing specifics -- choosing best letter, 
                    communicating with game server and reduction engine)
  """

  alias Hangman.Player
  require Logger

  @doc """
  Dynamically start a new player worker
  """

  @spec start_worker(Player.id(), atom, boolean, pid) :: :ok
  def start_worker(name, type, display, game_pid) do
    {:ok, _player_pid} = Player.Worker.Supervisor.start_child(name, type, display, game_pid)

    :ok
  end

  @doc "Issues proceed call to iterate player sequence"

  @spec proceed(Player.id()) :: tuple
  def proceed(id) do
    try do
      Player.Worker.proceed(id)
    catch
      :exit, reason ->
        _ = Logger.info("Caught exit in player controller, reason is #{inspect(reason)}")
        {:retry, reason}
    end
  end

  @doc "Issues guess request with guess data"

  @spec guess(Player.id(), tuple | String.t()) :: tuple
  def guess(id, data) when is_tuple(data) or is_binary(data) do
    Player.Worker.guess(id, data)
  end

  @doc "Issues request to stop worker"

  @spec stop_worker(Player.id()) :: atom
  def stop_worker(id) do
    Player.Worker.stop(id)
  end
end
