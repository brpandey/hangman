defmodule Game.Pid.Cache do 
	use GenServer
  
  @moduledoc """
  Module provides game server pid caching so
  a game server doesn't need to be reloaded
  on every use
  """
  
  require Logger
  
	@name __MODULE__
  
  @doc """
  GenServer start_link wrapper function
  """
  
  @spec start_link :: {:ok, pid}
	def start_link do
		Logger.info "Starting Hangman Game Pid Cache Server"
    
		args = nil
		options = [name: @name]
    
		GenServer.start_link(@name, args, options)
	end
  
  @doc """
  Checks registry cache for game server pid, returns cached pid or
  if not found returns new game pid
  """
  
  @spec get_server_pid(String.t, String.t) :: pid
	def get_server_pid(player_name, secret) do
		
		case Game.Server.whereis(player_name) do
			:undefined ->
				GenServer.call(@name, {:get_server, player_name, secret})
			pid -> 
				Game.Server.load(pid, player_name, secret)
				pid
		end
	end
  
  @doc """
  GenServer callback to initialize server process
  """

  @callback init(term) :: {}
	def init(_), do:	{:ok, nil}
  
  @doc """
  GenServer callback to retrieve game server pid
  """
  
  @callback handle_call({:atom, String.t, String.t}, {}, term) :: {}
	def handle_call({:get_server, player_name, secret}, _from, state) do
    
		#Check the registry again for the pid -- safeguard against race condition
		pid = 
		  case Game.Server.whereis(player_name) do
			  :undefined -> 
				  {:ok, pid} = 
            Game.Server.Supervisor.start_child(player_name, secret)
				  pid
			  pid ->
          Game.Server.load(pid, player_name, secret)
				  pid
		  end
    
		{:reply, pid, state}
	end
  
end
