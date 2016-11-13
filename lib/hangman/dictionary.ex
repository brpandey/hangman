defmodule Hangman.Dictionary do
  @moduledoc """
  Module provides central point to perform dictionary
  functions for clients for types, paths, random
  words, and lookup functionality.
  """

  alias Hangman.Dictionary.Cache

  @type kind :: :regular | :big  

  @root_path :code.priv_dir(:hangman_game)

  @paths %{
    :regular => "#{@root_path}/dictionary/regular/",
    :big => "#{@root_path}/dictionary/big/"
  }

  def max_random_words_request, do: 1000


  # dictionary hangman words range in size 2..28
  def key_range, do: 2..28


  def startup_params(opts) do
    dir_path = directory_path(opts)
    ingestion = ingestion_enabled(opts)
    {dir_path, ingestion}
  end


  @doc "Returns dictionary dir path"
  @spec directory_path(Keyword.t) :: String.t | no_return
  def directory_path(opts) do

    case Keyword.fetch(opts, :type) do
      {:ok, :regular} -> Map.get(@paths, :regular)
      {:ok, :big} -> Map.get(@paths, :big)
      _ -> raise "invalid dictionary type setting"
    end
  end


  @doc "Returns whether ingestion is enabled"
  @spec ingestion_enabled(Keyword.t) :: boolean | no_return
  def ingestion_enabled(opts) do
    case Keyword.fetch(opts, :ingestion) do
      {:ok, true} -> true
      {:ok, false} -> false
        _ -> raise "invalid ingestion setting"
    end
  end


  @doc "Returns random word secrets given count"
  @spec random(String.t) :: [String.t] | no_return
  def random(count) do
    # convert user input to integer value
    value = String.to_integer(count)
    cond do
      value > 0 and value <= max_random_words_request() ->
        lookup(:random, value)
      true ->
        raise HangmanError, "submitted random count value is not valid"
    end
  end

  @doc """
  Cache lookup routines

  The allowed modes:
    * `:random` - extracts specified count of random hangman words. 
    * `:tally` - retrieve letter tally associated with word length key
    * `:words` -  retrieve the word data lists associated with the word length key

  """

  @spec lookup(:random | :tally | :words, pos_integer) ::  [String.t] | Counter.t | Words.t

  def lookup(:random, count) do
    # Uses global server name to retrieve the server pid
    pid = Process.whereis(:hangman_dictionary_cache_server)  
    true = is_pid(pid) 
    
    Cache.lookup(pid, :random, count)
  end

  def lookup(:tally, length_key)
  when is_integer(length_key) and length_key > 0 do
    # Uses global server name to retrieve the server pid
    pid = Process.whereis(:hangman_dictionary_cache_server)  
    true = is_pid(pid) 
  
    Cache.lookup(pid, :tally, length_key)
  end

  def lookup(:words, length_key)
  when is_integer(length_key) and length_key > 0 do
    # Uses global server name to retrieve the server pid
    pid = Process.whereis(:hangman_dictionary_cache_server)
    true = is_pid(pid)

    Cache.lookup(pid, :words, length_key)
  end


  @doc "Handles dictionary server termination"
  def stop do
    pid = Process.whereis(:hangman_dictionary_cache_server)

    Cache.stop(pid)
  end


end
