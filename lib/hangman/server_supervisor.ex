defmodule Hangman.Server.Supervisor do
	use Supervisor

	#Hangman.Server.Supervisor is a first line supervisor
	#which will dynamically start its children

	def start_link do
		IO.puts "Starting Hangman Server Supervisor"

		Supervisor.start_link(__MODULE__, nil, name: :hangman_server_supervisor)
	end

	def start_child(player, secret) do	
		Supervisor.start_child(:hangman_server_supervisor, [player, secret])
	end

	def init(_) do

		children = [
			worker(Hangman.Server, []) 
		]

		#:simple_one_for_one to indicate that 
		#we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
	end
end