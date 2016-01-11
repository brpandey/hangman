defmodule Hangman.Cache do 
	use GenServer


	@name __MODULE__

	def start_link do
		IO.puts "Starting Hangman Server Cache"

		args = Nil
		options = [name: @name]

		GenServer.start_link(@name, args, options)
	end


	def get_server(player_name, secret) do
		
		case Hangman.Game.Server.whereis(player_name) do

			:undefined ->
				GenServer.call(@name, {:get_server, player_name, secret})

			pid -> 
				Hangman.Game.Server.load_game(pid, secret)
				pid
		end
	end

	def init(_), do:	{:ok, Nil}

	def handle_call({:get_server, player_name, secret}, _from, state) do

		#Check the registry again for the pid -- safeguard against race condition
		pid = 
		case Hangman.Game.Server.whereis(player_name) do

			:undefined -> 
				{:ok, pid} = Hangman.Server.Supervisor.start_child(player_name, secret)
				pid

			pid -> 
				Hangman.Game.Server.load_game(pid, secret)
				pid
		end

		{:reply, pid, state}
	end

end