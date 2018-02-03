defmodule Hangman.Player.Alert.Supervisor do
  @moduledoc false

  # Module implements supervisor functionality overseeing 
  # dynamically started player alert handler

  use Supervisor
  alias Hangman.Player
  require Logger

  @doc """
  Supervisor start and link wrapper function
  """

  @spec start_link :: Supervisor.on_start()
  def start_link do
    _ = Logger.debug("Starting Hangman Player Alert Supervisor")
    Supervisor.start_link(__MODULE__, {}, name: :player_alert_supervisor)
  end

  @doc """
  Starts a player alert handler dynamically
  """

  @spec start_child(String.t(), pid) :: Supervisor.on_start_child()
  def start_child(name, pid) when is_binary(name) do
    options = [id: name, pid: pid]
    Supervisor.start_child(:player_alert_supervisor, [options])
  end

  @doc """
  For each worker instantiated through start_child, 
  defines the worker specification to be supervised.

  Supervises each player alert handler
  """

  @callback init(term) :: {:ok, tuple}
  def init(_) do
    # define single child specification 
    # since we are starting children dynamically

    children = [
      worker(Player.Alert.Handler, [], restart: :transient)
    ]

    # :simple_one_for_one to indicate that 
    # we're starting children dynamically and children are of same type

    supervise(children, strategy: :simple_one_for_one)
  end
end
