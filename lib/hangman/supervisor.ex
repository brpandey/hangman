defmodule Root.Supervisor do 
	use Supervisor

  @moduledoc false
  
  _ = """
	Module is the root level supervisor.

  Serves as a nth line supervisor as
	it supervises Hangman.Game.System.Supervisor and 
	Hangman.Player.System.Supervisor, both of which
	are multi-depth supervisors
  """

  require Logger

	@name __MODULE__

  @doc """
  Supervisor start_link wrapper function
  """
  
  @spec start_link(Keyword.t) :: Supervisor.on_start
	def start_link(args) do
		Logger.info "Starting Hangman Supervisor, args: #{inspect args}"
		Supervisor.start_link(@name, args)
	end

  @doc """
  Defines child supervisor specifications to be supervised
  once supervisor started
  """

  @callback init(Keyword.t) :: {:ok, tuple}
	def init(args) do
		children = [
			supervisor(Game.System.Supervisor, []),
			supervisor(Player.System.Supervisor, [args])
		]

		supervise(children, strategy: :rest_for_one)
	end

end
