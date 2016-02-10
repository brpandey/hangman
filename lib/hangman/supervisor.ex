defmodule Hangman.Supervisor do 
	use Supervisor

	@name __MODULE__

	# Hangman.Server.Supervisor is a third line supervisor as
	# it supervises Hangman.System.Supervisor and 
	# Hangman.Player.System.Supervisor, both of which
	# are second line supervisors and 
	# also the "error kernel" Hangman.Process.Registry

	def start_link() do
		Supervisor.start_link(@name, nil)
	end

	def init(_) do
		children = [
			worker(Hangman.Process.Registry, []),
			supervisor(Hangman.System.Supervisor, []),
			#supervisor(Hangman.Player.System.Supervisor, [])
		]

		supervise(children, strategy: :rest_for_one)
	end

end
