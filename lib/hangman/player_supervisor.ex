defmodule Hangman.Player.Supervisor do
	use Supervisor

	@name __MODULE__
	
	# Hangman.Player.Supervisor is a first line supervisor
	# which will dynamically start its children

	def start_link(engine_server_pid, event_server_pid) do
		IO.puts "Starting Hangman Player Supervisor"

		Supervisor.start_link(@name, {engine_server_pid, event_server_pid}, 
                          name: :hangman_player_supervisor)
	end

	def start_child(player_name, player_type, game_server_pid) do	
		Supervisor.start_child(:hangman_player_supervisor, 
			[game_server_pid, player_name, player_type])
	end

	def init({engine_server_pid, event_server_pid}) do
		children = [
      # Use restart transient option -- only want restart if abnormal shutdown
			worker(Hangman.Player.FSM, 
             [engine_server_pid, event_server_pid], 
             restart: :transient) 
		]

		# :simple_one_for_one to indicate that 
		# we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
	end
end
