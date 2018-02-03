defmodule Hangman.Supervisor do
  @moduledoc false

  '''
  Module is the root level supervisor.

  Serves as a nth line supervisor as
  it supervises Hangman.Game.System.Supervisor, 
  Hangman.Player.System.Supervisor, and 
  Hangman.Player.Specific.Supervisor, all of which
  are multi-depth supervisors
  '''

  use Supervisor
  alias Hangman.{Game, Player}
  require Logger

  @name __MODULE__

  @doc """
  Supervisor start_link wrapper function
  """

  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(args) do
    _ = Logger.debug("Starting Hangman Supervisor, args: #{inspect(args)}")
    Supervisor.start_link(@name, args)
  end

  @doc """
  Defines child supervisor specifications to be supervised
  once supervisor started
  """

  @callback init(Keyword.t()) :: {:ok, tuple}
  def init(args) do
    children = [
      supervisor(Game.System.Supervisor, []),
      supervisor(Player.System.Supervisor, [args]),
      supervisor(Player.Specific.Supervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
