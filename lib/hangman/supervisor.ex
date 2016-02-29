defmodule Hangman.Supervisor do 
	use Supervisor

  require Logger

	@name __MODULE__

	# Hangman.Server.Supervisor is a third line supervisor as
	# it supervises Hangman.Game.System.Supervisor and 
	# Hangman.Player.System.Supervisor, both of which
	# are second line supervisors

	def start_link(args) do
		Logger.info "Starting Hangman Supervisor, args: #{inspect args}"

		Supervisor.start_link(@name, args)
	end

	def init(args) do
		children = [
			supervisor(Hangman.Game.System.Supervisor, []),
			supervisor(Hangman.Player.System.Supervisor, [args])
		]

		supervise(children, strategy: :rest_for_one)
	end

end
