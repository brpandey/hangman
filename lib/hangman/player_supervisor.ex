defmodule Hangman.Player.Supervisor do
	use Supervisor

	@name __MODULE__
	
	#Hangman.Player.Supervisor is a first line supervisor
	#which will dynamically start its children

	def start_link() do
		IO.puts "Starting Hangman Player Supervisor"

		Supervisor.start_link(@name, name: :hangman_player_supervisor)
	end

	def start_child(player_name, game_server_pid) do	
		Supervisor.start_child(:hangman_player_supervisor, 
			[player_name, game_server_pid])
	end

	def init(_) do
		children = [
			worker(Hangman.Player.FSM, []) 
		]

		#:simple_one_for_one to indicate that 
		#we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
	end
end