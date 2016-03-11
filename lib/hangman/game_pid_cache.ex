defmodule Game.Pid.Cache do 
	use GenServer
  
  @moduledoc """
  Module implements `GenServer` functionality to 
  provide `Game.Server` pid caching.  Ultimately relies
  on the `gproc` module to administer `registry` facilities.

  Pid `caching` prevents a `Game.Server` process
  from having to be loaded from scratch on every use
  """
  
  require Logger
  
	@name __MODULE__
  
  @doc """
  GenServer start link wrapper function
  """
  
  @spec start_link :: {:ok, pid}
	def start_link do
		Logger.info "Starting Game Pid Cache Server"
    
		args = nil
		options = [name: @name]
    
		GenServer.start_link(@name, args, options)
	end
  
  @doc """
  Checks registry cache for `Game.Server` pid given unique id, returns cached `pid` or
  if not found returns new game `pid`. Handles race conditions
  """
  
  @spec get_server_pid(name :: String.t, args :: String.t) :: pid
	def get_server_pid(player_name, secret) do
		
		case Game.Server.whereis(player_name) do
			:undefined ->
				GenServer.call(@name, {:get_server, player_name, secret})
			pid -> 
				Game.Server.load(pid, player_name, secret)
				pid
		end
	end
  
  @docp """
  GenServer callback to initialize server process
  """

  #@callback init(term) :: {}
	def init(_), do:	{:ok, nil}
  
  @docp """
  GenServer callback to retrieve game server pid
  """
  
  #@callback handle_call({:atom, String.t, String.t}, {}, term) :: {}
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
