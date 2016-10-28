defmodule Hangman.Player.Specific.Supervisor do
  @moduledoc false

  '''
  Module is a second line supervisor as it supervises
  three first-line supervisors and a worker.

  Module supervises those player supervisors which dynamically
  start workers, namely player worker supervisor and 
  the various player event handler supervisors.  As well
  as the player controller worker.
  '''

  use Supervisor
  import Supervisor.Spec
  alias Hangman.Player
  require Logger

  @doc """
  Supervisor start and link wrapper function
  """

  @spec start_link :: Supervisor.on_start
  def start_link do
    args = {}

    _ = Logger.debug "Starting Hangman Player Specific Supervisor," <> 
      " args: #{inspect args}"

    Supervisor.start_link(__MODULE__, args)
  end

  @doc """
  Specifies worker supervisor specifications.  
  Deploys a strategy of rest for one to isolate
  process tree errors without leaving dangling orphan processes
  """
  
  @callback init(term) :: {:ok, tuple}
  def init(_) do

    children = [
      supervisor(Player.Worker.Supervisor, []),
      supervisor(Player.Logger.Supervisor, []),
      supervisor(Player.Alert.Supervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end

end
