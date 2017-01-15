defmodule Hangman.Pass.Cache do
  @moduledoc """
  Module provides cache access to the game words pass.
  Given a player, a game and round number, `Pass.Cache` maintains a words pass 
  `cache` of current word passes.  The words are represented by `Words.t`.  

  Implements a `get/1` and `put/2` routine to retrieve and store these word 
  pass `Words.t`.

  Given a new `Hangman` game, initially the words pass is the size of all words
  in the dictionary of secret length k.  As each round proceeds, this is reduced by the 
  `Hangman` pattern sequence.  It is these remaining possible word set instances
  that are stored in the cache.

  After each player has made their `Hangman` round guess, the resultant reduced
  words `pass` data is stored into the `Pass.Cache` for access on the 
  subsequent round.  The expired `pass` data from stale rounds is subsequently 
  removed from the `cache`.

  Serves as the unified point for the reduction logic when handling data around the 
  `Pass.Cache`.
  """

  use GenServer
  alias Hangman.{Pass, Words}
  require Logger
  
  @ets_table_name :hangman_pass_cache


  # External API

  @doc "GenServer start link wrapper function"
  
  #@spec start_link :: Supervisor.on_start
  def start_link() do
    _ = Logger.debug "Starting Hangman Pass Cache GenServer"
    args = {}
    options = [name: :hangman_pass_cache] # same name for table as process
    GenServer.start_link(__MODULE__, args, options)
  end

  @doc """
  Routine to stop server normally
  """

  @spec stop() :: {}
  def stop() do
    GenServer.call :hangman_pass_cache, :stop
  end

  # GenServer callback to initialize server process

  #@callback init(term) :: {}
  def init(_) do
    # Loads ets table type set
    :ets.new(@ets_table_name, [:set, :named_table, :public])
    {:ok, {}}
  end

  # GenServer callback to stop server
  
  #@callback handle_call(:atom, {}, {}) :: {}
  def handle_call(:stop, _from, {}) do
    { :stop, :normal, :ok, {}}
  end 

  # GenServer callback to cleanup server state

  #@callback terminate(reason :: term, {}) :: term | no_return
  def terminate(_reason, _state) do
    :ok
  end


  @doc """
  Get routine retrieves `pass` words cache data given the pass key
  """

  @spec get(Pass.key) :: Words.t | no_return
  def get({id, game_no, round_no} = pass_key)
  when (is_binary(id) or is_tuple(id)) 
  and is_number(game_no) and is_number(round_no) do

    _ = Logger.debug("pass cache get: pass_key is #{inspect pass_key}")

    case do_get(:words, pass_key) do
      :error ->
        _ = Logger.debug("Unable to retrieve words from rounds_pass_cache," 
                     <> " given pass_key #{inspect pass_key}")
        #raise HangmanError, "words not found for key: #{inspect pass_key}"
        :error

      {:ok, data} -> 
        data
    end

  end


  @spec do_get(atom, Pass.key) :: Words.t | nil
  defp do_get(:words, {_id, _game_no, _round_no} = pass_key) do
    
    # Using match instead of lookup
    case :ets.match_object(@ets_table_name, {pass_key, :_}) do
      [] -> 
        :error
      [{^pass_key, data}] ->
        %Words{} = data # quick assert

        # delete this current pass in the table, 
        # since we only keep 1 pass for each user
        :ets.match_delete(@ets_table_name, {pass_key, :_})
    
        # return words :)
        {:ok, data}
    end

  end

  @doc """
  Put routine stores new `pass` words data, provided the pass key
  """

  @spec put(Pass.key, Words.t) :: :ok | no_return
  def put({_id, _game_no, _round_no} = pass_key, %Words{} = data) do

    # Make call to Pass Cache Writer to handle synchronized buffered writes 
    :ok = Pass.Cache.Writer.put(pass_key, data)
  end

  @doc """
  Delete pass data if single game is over
  """

  @spec delete(Pass.key) :: :ok
  def delete({_id, _game_no, _round_no} = pass_key) do
    # Using match instead of lookup
    case :ets.match_object(@ets_table_name, {pass_key, :_}) do
      [] -> :error
      [{^pass_key, _data}] ->        
        # delete this last current pass in the table, 
        :ets.match_delete(@ets_table_name, {pass_key, :_})   

        :ok
    end
  end


end
