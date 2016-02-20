defmodule Hangman.Game.Pid.Cache.Server do 
	use GenServer

  require Logger

	@name __MODULE__

	def start_link do
		Logger.info "Starting Hangman Game Pid Cache Server"

		args = nil
		options = [name: @name]

		GenServer.start_link(@name, args, options)
	end


	def get_server_pid(player_name, secret) do
		
		case Hangman.Game.Server.whereis(player_name) do

			:undefined ->
				GenServer.call(@name, {:get_server, player_name, secret})

			pid -> 
				Hangman.Game.Server.load_game(pid, secret)
				pid
		end
	end

	def init(_), do:	{:ok, nil}

	def handle_call({:get_server, player_name, secret}, _from, state) do

		#Check the registry again for the pid -- safeguard against race condition
		pid = 
		case Hangman.Game.Server.whereis(player_name) do

			:undefined -> 
				{:ok, pid} = Hangman.Game.Server.Supervisor.start_child(player_name, secret)
				pid

			pid -> 
				Hangman.Game.Server.load_game(pid, secret)
				pid
		end

		{:reply, pid, state}
	end

end
