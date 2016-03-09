defmodule Pass.Cache do
  use GenServer

	@moduledoc """
	Module implements ets table owning process for hangman words 
  pass state for a given player, round number.
  
  Performs primarily unserialized reads
	"""

  require Logger
  
  alias Dictionary.Cache, as: Cache
  
  @name __MODULE__
	@ets_table_name :engine_pass_table

  @type cache_key :: :chunks | {:pass, :game_start} | {:pass, :game_keep_guessing}

  # External API

  @doc """
  GenServer start_link wrapper function
  """
  
  @spec start_link :: Supervisor.on_start
  def start_link() do
    Logger.info "Starting Hangman Pass Cache GenServer"
    args = {}
    options = []
    GenServer.start_link(@name, args, options)
  end

  @doc """
  Routine to stop server normally
  """

  @spec stop(pid) :: {}
	def stop(pid) do
		GenServer.call pid, :stop
	end

  @doc """
  GenServer callback to initialize server process
  """

  @callback init(term) :: {}
  def init(_) do
    setup()
    {:ok, {}}
  end

  @doc """
  GenServer callback to retrieve game server pid
  """
  
  @callback handle_call(:atom, {}, {}) :: {}
	def handle_call(:stop, _from, {}) do
		{ :stop, :normal, :ok, {}}
	end 

  @doc """
  GenServer callback to cleanup server state
  """

  @callback terminate(reason :: term, {}) :: term | no_return
	def terminate(_reason, _state) do
		:ok
	end

  # Loads ets table type set
  
  @spec setup :: :atom
	defp setup() do
		:ets.new(@ets_table_name, [:set, :named_table, :public])
	end

  @doc """
  Routine retrieves pass tally given game start pass key
  Request not serialized through server process, since we are doing reads
  """

  @spec get(cache_key, Pass.key, Reduction.key) :: {Pass.key, Pass.t}
	def get({:pass, :game_start}, {id, game_no, round_no} = pass_key, reduce_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# Asserts
		{:ok, true} =	Keyword.fetch(reduce_key, :game_start)
		{:ok, length_key}  = Keyword.fetch(reduce_key, :secret_length)
		
		# Since this is the first pass, grab the words and tally from
		# the Dictionary Cache

		# Subsequent lookups will be from the pass table

		chunks = %Chunks{} = Cache.lookup(:chunks, length_key)
		tally = %Counter{} = Cache.lookup(:tally, length_key)

		pass_size = Chunks.count(chunks)
		pass_info = %Pass{ size: pass_size, tally: tally, last_word: ""}

		# Store pass info into ets table for round 2 (next pass)
    # Allow writer engine to execute (and distribute) as necessary
    Pass.Writer.write(pass_key, chunks)
	
		{pass_key, pass_info}
	end


  @doc """
  Game keep guessing engine pass routine
  Routine retrieves pass tally given pass key
  Request not serialized through server process, since we are doing reads
  """

  @spec get(cache_key, Pass.key, Reduction.key) :: {Pass.key, Pass.t}
	def get({:pass, :game_keep_guessing}, {id, game_no, round_no} = pass_key, 
               reduce_key)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do
    
		{:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
		{:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)
  
    # Send pass and reduce information off to Engine server
    # to execute (and distribute) as appropriate
    pass_info = Reduction.Engine.reduce(pass_key, regex_key, exclusion_set)

		{pass_key, pass_info}
	end


	@doc """
  Retrieves pass chunks from ets table with pass key"
  """
  
  @spec get(cache_key, Pass.key) :: Chunks.t | no_return
	def get(:chunks, {id, game_no, round_no} = pass_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
		
		# Using match instead of lookup, to keep processing on the ets side
		case :ets.match_object(@ets_table_name, {pass_key, :_}) do
			[] -> 
        raise HangmanError, 
        "counter not found for key: #{inspect pass_key}"

			[{_key, chunks}] ->
				%Chunks{} = chunks # quick assert

				# delete this current pass in the table, 
        # since we only keep 1 pass for each user
				:ets.match_delete(@ets_table_name, {pass_key, :_})
    
				# return chunks :)
				chunks
		end

	end
end
