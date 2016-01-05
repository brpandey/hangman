defmodule Hangman.Player.Supervisor do
	use Supervisor

	@name __MODULE__
	
	#Hangman.Player.Supervisor is a first line supervisor
	#which will dynamically start its children

	def start_link(engine_pid) do

		IO.puts "Starting Hangman Player Supervisor"

		Supervisor.start_link(@name, engine_pid, 
			name: :hangman_player_supervisor)
	
	end

	def start_child(_player_name, _game_server_pid) do	
		
		#For now, we are simulating this being passed through
		secrets = ["jovial"]
		player_name = "stanley"

		game_server_pid = Hangman.Cache.get_server(player_name, secrets)

		Supervisor.start_child(:hangman_player_supervisor, 
			[player_name, game_server_pid])

	end

	def init(engine_pid) do

		children = [
			worker(Hangman.Player, [engine_pid]) 
		]

		#:simple_one_for_one to indicate that 
		#we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
	end
end