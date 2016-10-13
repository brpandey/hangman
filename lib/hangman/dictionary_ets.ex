defmodule Hangman.Dictionary.ETS do

  require Logger

  @moduledoc """
  Module provides access to a dictionary word cache powered by `ETS`. 
  Provides lookup routines to access `chunks`, `tallys`, and `random` words.
  Handles all ETS specific operations while `Dictionary` serves
  as a wrapper.

  `Dictionary.ETS` loads the dictionary words into `chunks` and stores them
  into `ETS` via `Dictionary.Ingestion`.  Upon startup, letter frequency 
  `tallies` are computed and stored compactly into `ETS`. Words identified as 
  `random` are tagged and stored as well.
  """

  alias Hangman.{Chunks, Counter, Dictionary}

  @ets_table_name :dictionary_table

  # Used to insert the word list chunks and frequency counter tallies, 
  # indexed by word length e.g. 2..28, for both the normal and big 
  # dictionary file sizes
  @possible_length_keys MapSet.new(Dictionary.key_range)

  # Use for admin of random words extract 
  @ets_random_words_key :random_hangman_words
  @random_words_per_chunk 20
  @min_random_word_length 5
  @max_random_word_length 15


  @spec new :: atom
  def new, do: :ets.new(@ets_table_name, [:bag, :named_table, :public])

  @spec table_name :: atom
  def table_name, do: @ets_table_name


  @doc """
  Runs the dictionary ingestion process, loading the data into ETS
  """

  @spec setup(Keyword.t) :: :ok
  def setup(args) do

    case :ets.info(@ets_table_name) do
      :undefined -> Dictionary.Ingestion.run(args)
      _ -> raise HangmanError, "cache already setup!"
    end

    :ok
  end


  # READ

  @doc """
  Get has three modes: `:random`, `:counter`, `:chunks`

  :random -
  Retrieves all words tagged as random upon startup,
  then randomly chooses count words from this set, and returns
  the shuffled words result.

  :counter - 
  Retrieves dictionary tally counter given word length key

  :chunks -
  Retrieves chunks given word length key
  """

  @spec get(:random | :counter | :chunks, pos_integer) :: [String.t] | Counter.t | Chunks.t | no_return

  def get(:random, count) 
  when is_integer(count) and count > 0 do

    if count > Dictionary.max_random_words_request do
      raise HangmanError, "requested random words exceeds limit"
    end

    if :ets.info(@ets_table_name) == :undefined do
      raise HangmanError, "table not loaded yet"
    end

    # we use a module constant since the key doesn't change
    ets_key = @ets_random_words_key
      
    fn_reduce_random_words = fn
      {^ets_key, ets_value}, acc ->
        # NOTE: value first and acc second is orders of magnitude faster
        # then reversed
        List.flatten(ets_value, acc)
      _, acc -> acc 
    end

    # Since we are using a bag type, aggregate all random word key values
    randoms = :ets.foldl(fn_reduce_random_words, [], @ets_table_name)

    # seed random number generator with random seed

    # crypto method apparently produces genuinely random bytes 
    # w/o unintended side effects
    << a :: 32, b :: 32, c :: 32 >> = :crypto.strong_rand_bytes(12)
    r_seed = {a, b, c}

    
    _ = :rand.seed(:exsplus, r_seed)
    _ = :rand.seed(:exsplus, r_seed)

    # Note: Its not necessary to seed the random item generator but 
    # doing so ensures our results are really random

    # Using list comp to retrieve the list of count random words
    randoms = for _x <- 1..count do Enum.random(randoms) end

    # Shake and shuffle
    randoms = Enum.shuffle(randoms)

    randoms
  end


  def get(:counter, length_key) 
  when is_number(length_key) and length_key > 0 do

    if :ets.info(@ets_table_name) == :undefined do
      raise HangmanError, "table not loaded yet"
    end

    # validate that the key is within our valid set
    case Enum.any?(@possible_length_keys, fn x -> x == length_key end) do
      true -> 
        ets_key = key(:counter, length_key)
        
        # Grab the matching tally counter -- not sure if match_object or lookup is faster
        case :ets.match_object(@ets_table_name, {ets_key, :_}) do
          [] -> raise HangmanError, "counter not found for key: #{length_key}"
          [{_key, ets_value}] -> 
            counter = :erlang.binary_to_term(ets_value)
            counter
        end
      false -> raise HangmanError, "key not in set of possible keys!"
    end
  end

  
  def get(:chunks, length_key) do

    if :ets.info(@ets_table_name) == :undefined do
      raise HangmanError, "table not loaded yet"
    end

    # create chunk key given length
    ets_key = key(:chunk, length_key)
      
    fn_reduce_chunks = fn
      {^ets_key, ets_value}, acc ->
      # we pin to specified ets {chunk, length} key
        Chunks.add(acc, ets_value) 
      _, acc -> acc 
    end

    # since we are using the bag type, aggregate all chunk value given the same chunk_key
    # reduce into a single Chunks type
    chunks = :ets.foldl(fn_reduce_chunks, 
                        Chunks.new(length_key), @ets_table_name)

    chunks
  end


  @doc """
  Put function inserts data into the ETS via three modes: chunk, random, counter

  :chunk - 
  For each words list chunk, insert into ets

  :random - 
  For each chunk list of words and length key, within valid
  length key sizes, extract @random_words_per_chunk count words,
  dedup extracted set and insert into ets

  :counter -
  Inserts verified counter structure into ets

  Example key is {:counter, 8}
  Example {length, counter} is: {8,
      %Counter{entries: %{"a" => 14490, "b" => 4485, "c" => 7815,
      "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, "h" => 5111,
      "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, "m" => 5793,
      "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, "r" => 14211,
      "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, "w" => 2313,
      "x" => 662, "y" => 3395, "z" => 783}}}
  
  """

  @spec put(:chunk | :random | :counter, atom, 
            {pos_integer, [String.t] | Counter.t}) :: :ok
  
  def put(:chunk, table_name, {k, list})
  when is_list(list) and is_binary(hd(list)) do

    ets_key = key(:chunk, k)
    
    # record actual chunk size
    chunk_size = Kernel.length(list)

    # convert chunk into binary for compactness
    bin_chunk = :erlang.term_to_binary(list) 
    ets_value = {bin_chunk, chunk_size}
    :ets.insert(table_name, {ets_key, ets_value}) 
  end


  def put(:random, table_name, {length, words_chunk_list}) do
    cond do
      length >= @min_random_word_length and length <= @max_random_word_length ->
        # seed random number generator with random seed
        << a :: 32, b :: 32, c :: 32 >> = :crypto.strong_rand_bytes(12)
        r_seed = {a, b, c}
        
        _ = :rand.seed(:exsplus, r_seed)
        _ = :rand.seed(:exsplus, r_seed)
      
        # Grab @random_words_per_chunk random words
      
        rand = for _x <- 1..@random_words_per_chunk do 
          Enum.random(words_chunk_list) 
        end
      
        # Remove duplicate random words
        random_words = rand |> Enum.sort |> Enum.dedup

        :ets.insert(table_name, {@ets_random_words_key, random_words})

        #Logger.debug "hangman random words, length_key #{length}: #{inspect random_words}"

      true -> nil
    end

    :ok
  end


  def put(:counter, _table_name, {0, nil}), do: :ok

  def put(:counter, table_name, {length, %Counter{} = counter}) do

    Logger.debug "Dictionary.ETS.put, table is #{table_name} length is #{length}, counter is #{inspect counter}"

    ets_key = key(:counter, length)
    ets_value = :erlang.term_to_binary(counter)
    :ets.insert(table_name, {ets_key, ets_value})
  end


  # Simple helpers to generate tuple keys for ets based on word length size

  @spec key(:chunk, pos_integer) :: {atom, pos_integer}
  defp key(:chunk, length_key) do
    true = Enum.any?(@possible_length_keys, fn x -> x == length_key end)
    _ets_key = {:chunk, length_key}
  end


  @spec key(:counter, pos_integer) :: {atom, pos_integer}
  defp key(:counter, length_key) do
    true = Enum.any?(@possible_length_keys, fn x -> x == length_key end)
    _ets_key = {:counter, length_key}
  end


end
