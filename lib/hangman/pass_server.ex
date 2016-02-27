defmodule Hangman.Pass.Server do
  use GenServer

  require Logger

  alias Hangman.{Types.Reduction.Pass, Word.Chunks, Counter, Reduction.Engine}
  alias Hangman.Dictionary.Cache, as: DictCache

	@moduledoc """
	Table owning process for hangman words pass state
  for a given player, round number.

	Uses ets table. This module primarily does unserialized reads

	pass_key :: {id, game_no, round_no}
	ets_engine_key :: {:words, pass_key} | {:counter, pass_key}

	"""
  @name __MODULE__
	@ets_table_name :engine_pass_table


  # External API

  def start_link() do
    Logger.info "Starting Hangman Pass Server"
    args = {}
    options = []
    GenServer.start_link(@name, args, options)
  end

	def stop(pid) do
		GenServer.call pid, :stop
	end

  def init(_) do
    setup()
    {:ok, {}}
  end

	def handle_call(:stop, _from, {}) do
		{ :stop, :normal, :ok, {}}
	end 

	def terminate(_reason, _state) do
		:ok
	end

	defp setup() do
		:ets.new(@ets_table_name, [:set, :named_table, :public])
	end

  # request not serialized through server process, since we are doing reads
	# game start initial pass routine
	def get_pass(:game_start, {id, game_no, round_no} = pass_key, reduce_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do

		# Asserts
		{:ok, true} =	Keyword.fetch(reduce_key, :game_start)
		{:ok, length_key}  = Keyword.fetch(reduce_key, :secret_length)
		
		# Since this is the first pass, grab the words and tally from
		# the Dictionary Cache

		# Subsequent lookups will be from the pass table

		chunks = %Chunks{} = DictCache.Server.lookup(:chunks, length_key)
		tally = %Counter{} = DictCache.Server.lookup(:tally, length_key)

		pass_size = Chunks.get_count(chunks, :words)
		pass_info = %Pass{ size: pass_size, tally: tally, last_word: ""}

		# Store pass info into ets table for round 2 (next pass)
    Hangman.Pass.Writer.write(pass_key, chunks)
	
		{pass_key, pass_info}
	end

  # game keep guessing engine pass routine
	def get_pass(:game_keep_guessing, {id, game_no, round_no} = pass_key, 
               reduce_key)
 	when is_binary(id) and is_number(game_no) and is_number(round_no) do
    
		{:ok, exclusion_set} = Keyword.fetch(reduce_key, :guessed_letters)
		{:ok, regex_key} = Keyword.fetch(reduce_key, :regex_match_key)
    
    pass_info = Engine.reduce(pass_key, regex_key, exclusion_set)

		{pass_key, pass_info}
	end


	# "get pass chunks from ets table with pass key"
	def read_chunks({id, game_no, round_no} = pass_key)
	when is_binary(id) and is_number(game_no) and is_number(round_no) do
		
		# Using match instead of lookup, to keep processing on the ets side
		case :ets.match_object(@ets_table_name, {pass_key, :_}) do
			[] -> raise Hangman.Error, "counter not found for key: #{inspect pass_key}"

			[{_key, chunks}] ->
				%Chunks{} = chunks # quick assert

				# delete this current pass in the table, since we only keep 1 pass for each user
				:ets.match_delete(@ets_table_name, {pass_key, :_})
    
				# return chunks :)
				chunks
		end

	end
end
