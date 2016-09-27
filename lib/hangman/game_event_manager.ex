defmodule Hangman.Game.Event.Manager do
  alias Experimental.GenStage

  use GenStage
  require Logger

  ### Client API

  @doc """
  Starts the manager.
  """

  @spec start_link :: GenServer.on_start
  def start_link() do
    _ = Logger.debug "Starting Hangman Game Event Manager"
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end
  
  @doc """
  Sends an event and returns only after the event is
  dispatched.  Blocks until event is broadcasted
  """

  @spec async_notify(term) :: term
  def async_notify(event) do
    GenStage.cast(__MODULE__, {:notify, event})
  end

  
  ### Server Callbacks


  @callback init(term) :: {GenStage.type, tuple, GenStage.options}
  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  # Store the event into the queue

  @callback handle_cast(term, term) :: tuple
  def handle_cast({:notify, event}, {queue, demand}) do
    dispatch_async_events(:queue.in(event, queue), demand, [])
  end

  ## Store the demand

  @callback handle_demand(pos_integer, term) :: tuple
  def handle_demand(incoming_demand, {queue, demand}) do
    dispatch_async_events(queue, incoming_demand + demand, [])
  end

  ## Dispatches events as long as demand is greater than zero

  @spec dispatch_async_events(term, pos_integer, term) :: tuple
  defp dispatch_async_events(queue, demand, events) do
    with d when d > 0 <- demand,
    {item, queue} = :queue.out(queue),
    {:value, event} <- item do
      dispatch_async_events(queue, demand - 1, [event | events])
    else ## Returns events now that we've consumed the demand
        ## if events empty than so be it, else return the concatenated list
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end

end
