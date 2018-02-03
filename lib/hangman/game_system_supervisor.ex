defmodule Hangman.Game.System.Supervisor do
  @moduledoc false

  # Module implements `Supervisor` behaviour.

  # Module is a second line supervisor
  # as it supervises a first-line supervisor, Game.Server.Supervisor
  # along with the Game.Server.Controller and Game.Event.Manager

  use Supervisor
  alias Hangman.{Game}
  require Logger

  @doc """
  Supervisor start_link wrapper function
  """

  @spec start_link :: Supervisor.on_start()
  def start_link do
    _ = Logger.debug("Starting Hangman Game System Supervisor")

    Supervisor.start_link(__MODULE__, nil)
  end

  @doc """
  Supervisor callback to initialize server process

  Isolate errors to their process trees
  """

  @callback init(term) :: {}
  def init(_) do
    children = [
      supervisor(Game.Server.Supervisor, []),
      worker(Game.Server.Controller, []),
      worker(Game.Event.Manager, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
