defmodule Hangman.Game.Server.Controller do
  @moduledoc """
  Module provides dynamic startup of Game Servers.

  Starts up game server if not already started and handles game server
  process registry via gproc.

  Stops game server as well, when game is finished

  Note: Currently, the Controller maps one player_name to one game server.
  Thus effectively preventing a single game server from supporting multiple 
  unique players.  The simple idea for now, is to have multiple tiny game 
  servers map to multiple tiny players
  """

  use GenServer
  alias Hangman.{Game, Player}
  require Logger

  @name :game_server_controller

  @doc """
  GenServer start link wrapper function
  """

  @spec start_link :: {:ok, pid}
  def start_link do
    _ = Logger.debug("Starting Game Server Controller")

    args = nil
    options = [name: @name]

    GenServer.start_link(__MODULE__, args, options)
  end

  @doc """
  Checks registry cache for `Game.Server` pid given unique id, returns cached `pid` or
  if not found returns new game `pid`. Handles race conditions
  """

  @spec get_server(Player.id(), String.t() | [String.t()]) :: pid
  def get_server(id, secret) do
    case Game.Server.whereis(id) do
      :undefined ->
        GenServer.call(@name, {:get_server, id, secret})

      pid ->
        Game.Server.setup(pid, id, secret)
        pid
    end
  end

  @doc "Issues request to stop game server"

  @spec stop_server(Player.id()) :: atom
  def stop_server(id) do
    case Game.Server.whereis(id) do
      :undefined -> :ok
      pid -> Game.Server.stop(pid)
    end
  end

  # GenServer callback to initialize server process

  @callback init(term) :: tuple
  def init(_), do: {:ok, nil}

  # GenServer callback to retrieve game server pid

  @callback handle_call({atom, Player.id(), [String.t()]}, tuple, term) :: tuple
  def handle_call({:get_server, player_name, secret}, _from, state) do
    # Check the registry again for the pid -- safeguard against race condition
    pid =
      case Game.Server.whereis(player_name) do
        :undefined ->
          {:ok, pid} = Game.Server.Supervisor.start_child(player_name, secret)
          pid

        pid ->
          Game.Server.setup(pid, player_name, secret)
          pid
      end

    {:reply, pid, state}
  end
end
