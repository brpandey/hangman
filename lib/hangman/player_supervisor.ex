defmodule Player.Supervisor do
	use Supervisor

  @moduledoc false

  _ = """
  Module implements supervisor functionality, overseeing
  dynamically started player fsms.

  Player workers are dynamically started with event_pid,
  game_pid, player_name, and player_type parameters

  Restart strategy is transient

	Hangman.Player.Supervisor is a first line supervisor
	which will dynamically start its children
  """
  
  require Logger

	@name __MODULE__
	
  @doc """
  Supervisor start and link wrapper function
  """

  @spec start_link :: Supervisor.on_start
	def start_link() do
		Logger.info "Starting Hangman Player Supervisor"

		Supervisor.start_link(@name, {}, 
                          name: :hangman_player_supervisor)
	end

  @doc """
  Starts a player fsm worker dynamically
  """

  @spec start_child(String.t, :atom, pid, pid) :: Supervisor.on_start_child
	def start_child(player_name, player_type, game_pid, event_pid) do	

		Supervisor.start_child(:hangman_player_supervisor, 
			[event_pid, game_pid, player_name, player_type])
	end

  @doc """
  For each worker instantiated through start_child, 
  defines the worker specification to be supervised.

  Supervises each player fsm server
  """
  
  @callback init(term) :: {:ok, tuple}
	def init(_) do
		children = [
      # Use restart transient option -- only restart if abnormal shutdown
			worker(Player.FSM, [], restart: :transient) 
		]

		# :simple_one_for_one to indicate that 
		# we're starting children dynamically 
		supervise( children, strategy: :simple_one_for_one )
	end
end
