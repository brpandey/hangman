defmodule Hangman.Player.Events.Supervisor do
  use Supervisor

  require Logger

  @name __MODULE__

  def start_link() do
    Logger.info "Starting Hangman Player Events Supervisor"
    Supervisor.start_link(@name, {}, name: :hangman_player_events_supervisor)
  end

  def start_child(log \\ false, display \\ false) 
      when is_boolean(log) and is_boolean(display) do

    options = [file_output: log, display_output: display]
    Supervisor.start_child(:hangman_player_events_supervisor, [options])
  end

  def init(_) do
    children = [
      worker(Hangman.Player.Events.Server, [], restart: :transient)
    ]

		# :simple_one_for_one to indicate that 
		# we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
  end

  
end
