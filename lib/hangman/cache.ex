defmodule Hangman.Server.Cache do 
	use GenServer

	'''

	@name __MODULE__

	def start_link do
		IO.puts "Starting Hangman Server Cache"

		args = Nil
		options = [name: @name]

		GenServer.start_link(@name, args, options)
	end

	def server_process(player_name) do
		GenServer.call(@name, {:server_process, player_name})
	end




	def init() do
		{:ok, HashDict.new}
	end

	def handle_call({:server_process, player_name}, _from, hangman_servers) do

		case HashDict.fetch(hangman_servers, player_name) do

			{:ok, hangman_server} ->
				{:reply, hangman_server, hangman_servers}

			:error ->
				{} = Hangman.Server

		end


	end
'''

end