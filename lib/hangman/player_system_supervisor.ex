defmodule Hangman.Player.System.Supervisor do
	use Supervisor

  require Logger

  import Supervisor.Spec

	@name __MODULE__

	# Hangman.Player.System.Supervisor is a second line supervisor
	# as it supervises a first-line supervisor, Hangman.Player.Supervisor

	def start_link do
		Logger.info "Starting Hangman Player System Supervisor"

    Supervisor.start_link(@name, nil)
	end

	def init(_) do

    children = [
      worker(Hangman.Dictionary.Cache.Server, []),
      worker(Hangman.Pass.Server, []),
      supervisor(Hangman.Reduction.Engine, []),
      supervisor(Hangman.Pass.Writer, []),
      supervisor(Hangman.Player.Events.Supervisor, []),
      supervisor(Hangman.Player.Supervisor, [])
    ]

		supervise(children, strategy: :rest_for_one)
	end

end
