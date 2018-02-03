defmodule Hangman.Game.Server.Supervisor do
  @moduledoc false

  # Module implements supervisor behaviour.

  # Module is a first line supervisor
  # which will dynamically start its Game.Server children

  use Supervisor
  alias Hangman.{Game}
  require Logger

  @doc """
  Supervisor start_link wrapper function
  """

  @spec start_link :: Supervisor.on_start()
  def start_link do
    _ = Logger.debug("Starting Hangman Game Server Supervisor")
    Supervisor.start_link(__MODULE__, nil, name: :hangman_game_server_supervisor)
  end

  @doc """
  Starts game server dynamically
  """

  @spec start_child(Game.id(), String.t()) :: Supervisor.on_start_child()
  def start_child(id, secret) do
    Supervisor.start_child(:hangman_game_server_supervisor, [id, secret])
  end

  @doc """
  Supervisor callback to initialize server process
  """

  @callback init(term) :: {:ok, tuple}
  def init(_) do
    children = [
      worker(Game.Server, [], restart: :transient)
    ]

    # :simple_one_for_one to indicate that 
    # we're starting children dynamically 
    supervise(children, strategy: :simple_one_for_one)
  end
end
