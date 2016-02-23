defmodule Hangman.Process.Registry do
	  use GenServer

    require Logger
	  
	  import Kernel, except: [send: 2]

	 	@name __MODULE__

	  def start_link do
	    Logger.info "Starting Hangman Process Registry"
	    GenServer.start_link(@name, nil, name: :hangman_process_registry)
	  end

	  def stop(pid) do
		  GenServer.call pid, :stop
	  end

	  def register_name(key, pid) do
	    GenServer.call(:hangman_process_registry, {:register_name, key, pid})
	  end

	  def whereis_name(key) do
	    GenServer.call(:hangman_process_registry, {:whereis_name, key})
	  end

	  def unregister_name(key) do
	    GenServer.call(:hangman_process_registry, {:unregister_name, key})
	  end

	  def send(key, message) do
	    case whereis_name(key) do
	      :undefined -> {:badarg, {key, message}}
	      pid ->
	        Kernel.send(pid, message)
	        pid
	    end
	  end


	  def init(_) do
	    {:ok, HashDict.new}
	  end

	  def handle_call(:stop, _from, {}) do
		  { :stop, :normal, :ok, {}}
	  end 
    

	  def handle_call({:register_name, key, pid}, _, process_registry) do
	    case HashDict.get(process_registry, key) do
	      nil ->
	        # Sets up a monitor to the registered process
	        Process.monitor(pid)
	        {:reply, :yes, HashDict.put(process_registry, key, pid)}
	      _ ->
	        {:reply, :no, process_registry}
	    end
	  end

	  def handle_call({:whereis_name, key}, _, process_registry) do
	    {:reply, HashDict.get(process_registry, key, :undefined), process_registry}
	  end

	  def handle_call({:unregister_name, key}, _, process_registry) do
	    {:reply, key, HashDict.delete(process_registry, key)}
	  end

	  def handle_info({:DOWN, _, :process, pid, _}, process_registry) do
	    {:noreply, deregister_pid(process_registry, pid)}
	  end

	  def handle_info(_, state), do: {:noreply, state}


	  defp deregister_pid(process_registry, pid) do
	    # We'll walk through each {key, value} item, and delete those elements whose
	    # value is identical to the provided pid.
	    Enum.reduce(
	      process_registry,
	      process_registry,
	      fn
	        ({registered_alias, registered_process}, registry_acc) when registered_process == pid ->
	          HashDict.delete(registry_acc, registered_alias)

	        (_, registry_acc) -> registry_acc
	      end
	    )
	  end

	  def terminate(_reason, _state) do
		  :ok
	  end

end
