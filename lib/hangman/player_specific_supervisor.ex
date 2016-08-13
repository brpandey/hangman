defmodule Hangman.Player.Specific.Supervisor do
  use Supervisor

  @moduledoc false

  '''
  Module is a second line supervisor as it supervises
  two first-line supervisors.

  Module supervises those player supervisors which dynamically
  start workers, namely player supervisor and player events supervisors
  '''

  alias Hangman.Player

  require Logger

  import Supervisor.Spec

  @name __MODULE__

  @doc """
  Supervisor start and link wrapper function
  """

  @spec start_link :: Supervisor.on_start
  def start_link do
    args = {}

    Logger.info "Starting Hangman Player Specific Supervisor," <> 
      " args: #{inspect args}"

    Supervisor.start_link(@name, args)
  end

  @doc """
  Specifies worker supervisor specifications.  
  Deploys a strategy of one for one to isolate
  process tree errors
  """
  
  @callback init(term) :: {:ok, tuple}
  def init(_) do

    children = [
      supervisor(Player.Supervisor, []),
      supervisor(Player.Alert.Supervisor, []),
      supervisor(Player.Logger.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
