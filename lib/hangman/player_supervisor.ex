defmodule Hangman.Player.Supervisor do
	use Supervisor

  require Logger

	@name __MODULE__
	
	# Hangman.Player.Supervisor is a first line supervisor
	# which will dynamically start its children

	def start_link() do
		Logger.info "Starting Hangman Player Supervisor"

		Supervisor.start_link(@name, {}, 
                          name: :hangman_player_supervisor)
	end

	def start_child(player_name, player_type, game_pid, event_pid) do	

		Supervisor.start_child(:hangman_player_supervisor, 
			[event_pid, game_pid, player_name, player_type])
	end

	def init(_) do
		children = [
      # Use restart transient option -- only restart if abnormal shutdown
			worker(Hangman.Player.FSM, [], restart: :transient) 
		]

		# :simple_one_for_one to indicate that 
		# we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
	end
end
