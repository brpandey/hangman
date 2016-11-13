defmodule Hangman.Dictionary.Cache do
  @moduledoc """
  Module implements a GenServer process 
  providing access to a dictionary word cache. 
  Handles lookup routines to access `words`, `tallys`, and `random` words.

  Serves as a wrapper around dictinary specific implementation
  """

  use GenServer
  alias Hangman.Dictionary
  require Logger

  # External API

  @doc """
  GenServer start link wrapper function
  """

  @spec start_link(Keyword.t) :: {:ok, pid}
  def start_link(args) do
    options = [name: :hangman_dictionary_cache_server]
    GenServer.start_link(__MODULE__, args, options)
  end

  @doc """
  Cache lookup routines

  The allowed modes:
    * `:random` - extracts count number of random hangman words. 
    * `:tally` - retrieve letter tally associated with word length key
    * `:words` -  retrieve the word data lists associated with the word length key
  """

  @spec lookup(pid, atom, pos_integer) ::  [String.t] | Counter.t | Words.t | no_return
  def lookup(pid, :random, count) do
    GenServer.call pid, {:lookup_random, count}
  end

  def lookup(pid, :tally, length_key)
  when is_number(length_key) and length_key > 0 do
    GenServer.call pid, {:lookup_tally, length_key}
  end

  def lookup(pid, :words, length_key)
  when is_number(length_key) and length_key > 0 do
    GenServer.call pid, {:lookup_words, length_key}
  end

  @doc """
  Routine to stop server normally
  """

  @spec stop(none | pid) :: {}
  def stop(pid) when is_pid(pid) do
    GenServer.call pid, :stop
  end


  @doc """
  GenServer callback to initalize server process

  Kicks off ingestion process to load dictionary words
  """

  @callback init(Keyword.t) :: tuple
  def init(args) do

    _ = Logger.debug "Starting Hangman Dictionary Cache Server, args #{inspect args}"

    Dictionary.ETS.setup(args)

    {:ok, {}}
  end

  @docp """
  GenServer callback to retrieve random hangman word
  """

  #@callback handle_call({:atom, pos_integer}, {}, {}) :: {}
  def handle_call({:lookup_random, count}, _from, {}) do
    data = Dictionary.ETS.get(:random, count)
    {:reply, data, {}}
  end

  @docp """
  GenServer callback to retrieve tally given word length key
  """

  #@callback handle_call({:atom, pos_integer}, {}, {}) :: {}
  def handle_call({:lookup_tally, length_key}, _from, {})
  when is_integer(length_key) do
    data = Dictionary.ETS.get(:counter, length_key)
    {:reply, data, {}}
  end

  @docp """
  GenServer callback to retrieve word lists given word length key
  """
  #@callback handle_call({:atom, pos_integer}, {}, {}) :: {}
  def handle_call({:lookup_words, length_key}, _from, {}) do
    data = Dictionary.ETS.get(:words, length_key)
    {:reply, data, {}}
  end
 
  @docp """
  GenServer callback to stop server normally
  """

  #@callback handle_call(:atom, pid, {}) :: {}
  def handle_call(:stop, _from, {}) do
    { :stop, :normal, :ok, {}}
  end 

  @docp """
  GenServer callback to cleanup server state
  """

  #@callback terminate(reason :: term, {}) :: term | no_return
  def terminate(reason, _state) do
    _ = Logger.debug("Dictionary Cache Server terminating, reason #{reason}")
    :ok
  end


end

