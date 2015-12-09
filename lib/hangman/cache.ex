defmodule Hangman.Server.Cache do 
	use GenServer


	@name __MODULE__

	def start_link do
		IO.puts "Starting Hangman Server Cache"

		args = Nil
		options = [name: @name]

		GenServer.start_link(@name, args, options)
	end

	def get_server(player_name, secret) do
		GenServer.call(@name, {:get_server, player_name, secret})
	end


	def init(state), do:	{:ok, HashDict.new}

	def handle_call({:get_server, player_name, secret}, _from, hangman_servers) do

		case HashDict.fetch(hangman_servers, player_name) do

			{:ok, hangman_server_pid} ->

				{:reply, hangman_server_pid, hangman_servers}

			:error ->
				{:ok, hangman_server_pid} = Hangman.Server.start(secret)

				IO.puts "Creating a new hangman server"
				
				{
					:reply, 
					hangman_server_pid, 
					HashDict.put(hangman_servers, player_name, hangman_server_pid)
				}

		end

	end

end