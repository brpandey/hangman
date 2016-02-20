defmodule Hangman.Supervisor do 
	use Supervisor

  require Logger

	@name __MODULE__

	# Hangman.Server.Supervisor is a third line supervisor as
	# it supervises Hangman.Game.System.Supervisor and 
	# Hangman.Player.System.Supervisor, both of which
	# are second line supervisors and 
	# also the "error kernel" Hangman.Process.Registry

	def start_link() do
		Logger.info "Starting Hangman Supervisor"

		Supervisor.start_link(@name, nil)
	end

	def init(_) do
		children = [
			worker(Hangman.Process.Registry, []),
			supervisor(Hangman.Game.System.Supervisor, []),
			supervisor(Hangman.Player.System.Supervisor, [])
		]

		supervise(children, strategy: :rest_for_one)
	end

end
