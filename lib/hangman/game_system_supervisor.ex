defmodule Hangman.Game.System.Supervisor do 
	use Supervisor

  require Logger

	@name __MODULE__

	# Hangman.System.Supervisor is a second line supervisor
	# as it supervises a first-line supervisor, Hangman.Server.Supervisor
	# along with the Hangman.Cache GenServer

	def start_link do
		Logger.info "Starting Hangman Game System Supervisor"

		Supervisor.start_link(@name, nil)
	end

	def init(_) do

		children = [
				supervisor(Hangman.Game.Server.Supervisor, []),
				worker(Hangman.Game.Pid.Cache.Server, [])
		]

		supervise(children, strategy: :one_for_one)	
	end

end
