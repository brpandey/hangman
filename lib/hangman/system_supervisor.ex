defmodule Hangman.System.Supervisor do 
	use Supervisor

	@name __MODULE__

	# Hangman.System.Supervisor is a second line supervisor
	# as it supervises a first-line supervisor, Hangman.Server.Supervisor
	# along with the Hangman.Cache GenServer

	def start_link do
		IO.puts "Starting Hangman System Supervisor"

		Supervisor.start_link(@name, Nil)
	end

	def init(_) do

		children = [
				supervisor(Hangman.Server.Supervisor, []),
				worker(Hangman.Cache, [])
		]

		supervise(children, strategy: :one_for_one)	
	end

end