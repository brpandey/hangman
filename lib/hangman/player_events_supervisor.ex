defmodule Hangman.Player.Events.Supervisor do
  use Supervisor

  @moduledoc """
  Module implements supervisor functionality overseeing 
  dynamically started player events servers

  Player events server processes are started with 
  both log and display options off
  """

  require Logger

  @name __MODULE__

  @doc """
  Supervisor start and link wrapper function
  """

  @spec start_link :: Supervisor.on_start
  def start_link do
    Logger.info "Starting Hangman Player Events Supervisor"
    Supervisor.start_link(@name, {}, name: :player_events_supervisor)
  end

  @doc """
  Starts a player events worker dynamically
  """

  @spec start_child(none | boolean, none | boolean) 
  :: Supervisor.on_start_child
  def start_child(log \\ false, display \\ false)
  when is_boolean(log) and is_boolean(display) do
    
    options = [file_output: log, display_output: display]
    Supervisor.start_child(:player_events_supervisor, [options])
  end
  
  @doc """
  For each worker instantiated through start_child, 
  defines the worker specification to be supervised.

  Supervises the player events server
  """
  
  @callback init(term) :: {:ok, tuple}
  def init(_) do
    # define single child specification 
    # since we are starting children dynamically

    children = [
      worker(Hangman.Player.Events.Server, [], restart: :transient)
    ]

		# :simple_one_for_one to indicate that 
		# we're starting children dynamically

		supervise( children, strategy: :simple_one_for_one )
  end
  
end
