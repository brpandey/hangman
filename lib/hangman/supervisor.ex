defmodule Hangman.Supervisor do 
	use Supervisor

	@name __MODULE__

	# Hangman.Server.Supervisor is a third line supervisor as
	# it supervises Hangman.System.Supervisor,
	# which is a second line supervisor and also
	# the "error kernel" Hangman.Process.Registry

	def start_link() do
		Supervisor.start_link(@name, Nil)
	end

	def init(_) do
		children = [
			worker(Hangman.Process.Registry, []),
			supervisor(Hangman.System.Supervisor, [])
		]

		supervise(children, strategy: :rest_for_one)
	end

end