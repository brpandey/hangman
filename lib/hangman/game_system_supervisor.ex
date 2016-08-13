defmodule Hangman.Game.System.Supervisor do 
  use Supervisor

  @moduledoc false

  '''
  Module implements `Supervisor` behaviour.

  Module is a second line supervisor
  as it supervises a first-line supervisor, Game.Server.Supervisor
  along with the Game.Pid.Cache
  '''
  
  require Logger

  alias Hangman.{Game}
  
  @name __MODULE__


  @doc """
  Supervisor start_link wrapper function
  """
  
  @spec start_link :: Supervisor.on_start
  def start_link do
    Logger.info "Starting Hangman Game System Supervisor"

    Supervisor.start_link(@name, nil)
  end

  @doc """
  Supervisor callback to initialize server process

  Isolate errors to their process trees
  """

  @callback init(term) :: {}
  def init(_) do

    children = [
        supervisor(Game.Server.Supervisor, []),
        worker(Game.Pid.Cache, []),
        worker(Game.Event.Manager, [])
    ]

    supervise(children, strategy: :one_for_one) 
  end

end
