defmodule Hangman.Player.System.Supervisor do
	use Supervisor

  import Supervisor.Spec

	@name __MODULE__

	# Hangman.Player.System.Supervisor is a second line supervisor
	# as it supervises a first-line supervisor, Hangman.Player.Supervisor
	# along with the Hangman.WordEngine worker

	def start_link do
		IO.puts "Starting Hangman Player System Supervisor"

		result = {:ok, sv} = Supervisor.start_link(@name, nil)

		start_workers(sv)

		result
	end

	# Since we need to pass the WordEngine pid to the Player Supervisor
	# we instantiate the children this alternate way

	def start_workers(sv) do

	
    {:ok, dictionary_cache_pid} = 
			Supervisor.start_child(sv, worker(Hangman.Dictionary.Cache.Server, []))
	
		{:ok, engine_pid} = 
			Supervisor.start_child(sv, worker(Hangman.Reduction.Engine.Server, 
                                        [dictionary_cache_pid]))
	
    {:ok, notify_pid} = 
      Supervisor.start_child(sv, worker(Hangman.Player.Events.Notify, []))

		Supervisor.start_child(sv, supervisor(Hangman.Player.Supervisor, 
			[engine_pid, notify_pid]))

	end

	def init(_) do
		supervise([], strategy: :rest_for_one)
	end

end
