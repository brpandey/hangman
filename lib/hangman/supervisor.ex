defmodule Hangman.Supervisor do 

	use Supervisor

	#Initially supervise the server 
	#once this works, we will supervise the cache

	def start_link(secret) when is_binary(secret) do

		IO.puts "Starting single game Hangman.Server"

		:supervisor.start_link(__MODULE__, secret)

	end


	def start_link(secrets) when is_list(secrets) do

		IO.puts "Starting multiple game Hangman.Server"

		:supervisor.start_link(__MODULE__, secrets)

	end

	def init(secret) do

		child_processes = [worker(Hangman.Server, [secret])]
		supervise child_processes, strategy: :one_for_one

	end

end