defmodule Hangman.Reduction.Engine.Worker do
  @moduledoc """
  Module implements workers that handle `Hangman` words reduction.
  Used primarily by `Reduction.Engine` through `reduce_and_store/4` to perform
  a series of steps:

    * Retrieves `pass` data from `Pass.Cache`. 
    * Reduces word set based on `reduce_key`.
    * Stores reduced set back into `Pass.Cache`.  
    * Returns new `Pass`.
  """

  use GenServer
  alias Hangman.{Pass, Words}
  require Logger

  @doc """
  GenServer start_link wrapper function
  """

  @spec start_link(pos_integer) :: GenServer.on_start()
  def start_link(worker_id) do
    _ = Logger.debug("Starting Engine Reduce Worker #{worker_id}")

    args = {}
    options = [name: via_tuple(worker_id)]
    GenServer.start_link(__MODULE__, args, options)
  end

  @doc """
  Primary `worker` function which retrieves current `pass words` data,
  filters words with `regex`, tallies reduced word stream, creates new
  `Words` abstraction and stores it back into words pass table.

  If pass size happens to be small enough, will also return
  remaining `Hangman` possible words left to aid in `guess` selection. 

  Returns `pass`. Method is serialized.
  """

  @spec reduce_and_store(pos_integer, Pass.key(), Regex.t(), map) :: Pass.t()
  def reduce_and_store(worker_id, pass_key, regex_key, %MapSet{} = exc) do
    l = [worker_id, pass_key, regex_key, exc]

    _ =
      Logger.debug(
        "reduction engine worker #{worker_id}, " <> "reduce and store, args #{inspect(l)}"
      )

    GenServer.call(via_tuple(worker_id), {:reduce_and_store, pass_key, regex_key, exc})
  end

  # Used to register / lookup process in process registry via gproc

  @spec via_tuple(pos_integer) :: tuple
  defp via_tuple(worker_id) do
    {:via, :gproc, {:n, :l, {:reduction_engine_worker, worker_id}}}
  end

  @doc """
  Terminate callback
  No special cleanup
  """

  @callback terminate(term, term) :: :ok
  def terminate(_reason, _state) do
    _ = Logger.debug("Terminating Reduction Engine Worker Server")
    :ok
  end

  # GenServer callback function to handle reduce and store request

  # @callback handle_call(atom, Pass.key, Regex.t, MapSet.t, term, tuple) :: tuple
  def handle_call({:reduce_and_store, pass_key, regex_key, exclusion}, _from, {}) do
    pass_info = do_reduce_and_store(pass_key, regex_key, exclusion)
    {:reply, pass_info, {}}
  end

  # Primary worker function which retrieves current pass words data,
  # filters words with regex.

  # Takes reduced word set and tallies it, creates new
  # Chunk abstraction and stores it back into words pass table.

  # If pass size happens to be small enough, will also return
  # remaining hangman possible words left to aid in guess selection. 

  # Returns pass metadata.

  @spec do_reduce_and_store(Pass.key(), Regex.t(), Enumerable.t()) :: Pass.t()
  defp do_reduce_and_store(pass_key, regex_key, exclusion) do
    # Request word list data from Pass
    data = %Words{} = Pass.Reduction.words(pass_key)

    # REDUCE
    # Create new Words abstraction after filtering out failed word matches
    new_data = %Words{} = data |> Words.filter(regex_key)

    # STORE
    # Write to cache
    receipt = %Pass{} = Pass.Reduction.store(pass_key, new_data, exclusion)

    # Return pass receipt metadata
    receipt
  end
end
