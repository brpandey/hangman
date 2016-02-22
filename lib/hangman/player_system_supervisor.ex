defmodule Hangman.Player.System.Supervisor do
	use Supervisor

  require Logger

  import Supervisor.Spec

	@name __MODULE__

	# Hangman.Player.System.Supervisor is a second line supervisor
	# as it supervises a first-line supervisor, Hangman.Player.Supervisor

	def start_link do
		Logger.info "Starting Hangman Player System Supervisor"

		result = {:ok, sv} = Supervisor.start_link(@name, nil)

		start_workers(sv)

		result
	end

	# Since we need to pass the WordEngine pid to the Player Supervisor
	# we instantiate the children this alternate way

	def start_workers(sv) do
    {:ok, _dictionary_cache_pid} = 
			Supervisor.start_child(sv, worker(Hangman.Dictionary.Cache.Server, []))
	
		{:ok, _pass_pid} = 
			Supervisor.start_child(sv, worker(Hangman.Pass.Server, []))
	
    {:ok, _reduction_engine_pool_sup_pid} = 
      Supervisor.start_child(sv, supervisor(Hangman.Reduction.Engine, []))

    {:ok, _pass_writer_pool_sup_pid} = 
      Supervisor.start_child(sv, supervisor(Hangman.Pass.Writer, []))

    {:ok, notify_pid} = 
      Supervisor.start_child(sv, worker(Hangman.Player.Events.Server, []))

		Supervisor.start_child(sv, supervisor(Hangman.Player.Supervisor, 
			[notify_pid]))
	end

	def init(_) do
		supervise([], strategy: :rest_for_one)
	end

end
