defmodule Hangman.Supervisor do 
'''
	use Supervisor

	def start_link(secret) do
		IO.puts "Starting Hangman.Server"

		:supervisor.start_link(__MODULE__, secret)

	end

	def init(secret) do
		child_processes = [worker(Hangman.Server, [secret])]
		supervise child_processes, strategy: one_for_one
	end
'''

end