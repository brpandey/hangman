defmodule Hangman.Dictionary.Ingestion do
  @moduledoc """
  Module handles the ingestion of hangman dictionary words
  through the coordination of `Ingestion.First.Flow` and `Ingestion.Cache.Flow`

  Saves ingestion state in intermediary cache partition files and finally in
  ets dump file

  Module transforms the dictionary file in three steps

  a) a preprocessing step, which ingests the dictionary file and
  generates ingestion cache partition files

  b) ingestion of cache files into ETS

  c) if both steps are done, we generate an ets table file which can be loaded
  upon startup the next time through

  For the first step, we run flow and store the results
  in partitioned files.  We pass a map of file_pids keyed by word length key, to 
  facilitate writing to the intermediate cache files

  After the inital run with the dictionary file, we run flow on the cached 
  output files (the intermediate partition files) saving the initial flow intermediary 
  processing -- windowing etc.  Allowing us to generate and load the relevant data 
  (word list chunks, random word generation, tally generation) into ETS concurrently.

  Lastly, once both the flows have finished we generate an ets file. 
  On subsequent runs, this bypasses extra flow processing as the ets file 
  is loaded to create the ets
  """

  alias Hangman.{Dictionary, Ingestion}

  # Standard name for hangman dictionary file
  # To distinguish between types, we place file in different directory
  # with directory name marking the difference e.g. "big"
  @dictionary_file_name "words.txt"

  # Cache Partition
  @cache_dir "cache/"
  @partition_file_prefix "words_key_"
  @partition_file_suffix ".txt"

  @ets_file_name "ets_table"

  # Manifest file existance indicates initial flow pass has been completed
  @manifest_file_name "manifest"

  # Used in writing intermediate files and conversely parsing them
  @line_delimiter "    \n"
  @key_value_delimiter ": "

  def delimiter(:line), do: @line_delimiter
  def delimiter(:kv), do: @key_value_delimiter


  @doc """
  Routine kicks off the ingestion process by 
  setting up the proper state and then running it

  If we have pregenerated an ets table file previously
  use that to load the ets and bypass flow processing
  """

  @spec run(Keyword.t) :: :ok
  def run(args) do

    case Dictionary.startup_params(args) do
      {_dir, false} -> :ok # if ingestion is not enabled return :ok

      {dir, true} ->
        dictionary_path = dir <> @dictionary_file_name
        cache_full_dir = dir <> @cache_dir
        ets_file_path = cache_full_dir <> @ets_file_name

        # Check to see if we've already written to an ets cache file
        :ok = case File.exists?(ets_file_path) do
          true -> 
            args = {:ets, ets_file_path} 
            args |> setup
          false -> 
            args = {:flow, dictionary_path, cache_full_dir, ets_file_path} 
            args |> setup |> process
        end

        :ok
    end
  end


  @doc """
  Setup has two modes: a) :ets b) :flow

  a) :ets
  Checks if there is an ets cache file that has been pre-generated. If so, we can
  avoid running the flow computations because the table is ready to load from the file.

  b) :flow
  Loads environment to run initial ingestion pass through the dictionary file.
  If this is the first time through, we set up intermediary ingestion cache files
  If not, we ensure the partition manifest file is present indicating the initial
  run is complete and execute the cache ingestion run loading chunks and generating 
  random words into ETS as well as generating tally data
  """

  @spec setup({:ets, binary} | {:flow, binary, binary, binary}) :: 
  {:full, binary, binary, map, binary} | {:cache, binary, binary} | :ok

  def setup({:ets, ets_path}) when is_binary(ets_path) do
    Dictionary.ETS.load(ets_path)
    :ok
  end

  def setup({:flow, dictionary_path, cache_dir, ets_path})
  when is_binary(dictionary_path) and is_binary(cache_dir) and is_binary(ets_path) do

    # Check to see if dictionary path is valid, if not error
    case File.exists?(dictionary_path) do
      true -> :ok
      false -> raise "Unable to find dictionary file" 
    end

    # The presence of a partition manifest file indicates whether we have finished
    # the partition steps, if not found we need to partition

    # This allows us to run the main flow logic once and store the results of the
    # flow in a set of files to be quickly loaded into ETS on second pass
    # These generate partition files are cache files so to speak for Dictionary.Flow.Cache


    # So, let's check whether the partition files have already been generated
    # If so, forward to Dictionary.Flow.Cache.run
    # If not, setup partition cache file state and setup Flow with writing to partition files

    case File.exists?(cache_dir <> @manifest_file_name) do
      false -> 
        # Manifest file doesn't exist -> we haven't partitioned into files yet
        
        # Setup the cache state
        # Remove the partition cache dir + files in case it exists, cleaning any prior state

        # NOTE: SAFE TO USE RM_RF SINCE WE DON"T ASK FOR USER INPUT INVOLVING PATHS
        # ALL COMPILE-TIME STATIC PATHS
        _ = File.rm_rf!(cache_dir) 
        
        # Start clean with a new cache dir
        :ok = File.mkdir!(cache_dir)
        
        # Take a range of key values, and generate a map which contain k-v parts, where
        # the key is the word length, and values are open file pids
        
        # This map will be used when doing the partition each - file write in the 
        # context of the flow processing

        partial_name = cache_dir <> @partition_file_prefix  
      
        key_file_map = Dictionary.key_range |> Enum.reduce(%{}, fn key, acc ->
          file_name = partial_name <> "#{key}" <> @partition_file_suffix

          {:ok, pid} = File.open(file_name, [:append])
          Map.put(acc, key, pid)
        end)
        
        {:full, dictionary_path, cache_dir, key_file_map, ets_path}

      true -> 
        {:cache, cache_dir, ets_path}
    end

  end
  
  @doc """
  Process method supports two modes: new, cache, and full

  `New` runs the initial ingestion concurrently chunking the original dictionary
  file into key based partition files which contain the various
  windowed data

  `Cache` runs a flow against the cached partitioned files and 
  concurrently generates and loads all the relevent information into
  memory

  Full basically invokes new and cache

  `Full` runs the full ingestion process by first
  running the initial ingestion flow process followed by 
  a state cleanup, then running the ingestion cache flow process
  """

  @spec process({:new, binary, binary, map} |
                {:cache, binary, binary} |
                {:full, binary, binary, map, binary}) :: :ok

  def process({:full, dictionary_path, cache_dir, 
               %{} = key_file_map, ets_path}) do
    process({:new, dictionary_path, cache_dir, key_file_map})
    process({:cache, cache_dir, ets_path})
    
    :ok
  end

  def process({:new, dictionary_path, cache_dir, %{} = key_file_map}) do
    {:ok, key_file_map} = Ingestion.First.Flow.run(dictionary_path, key_file_map)
    cleanup(cache_dir, key_file_map)

    :ok
  end

  def process({:cache, cache_dir, ets_path}) do
    Ingestion.Cache.Flow.run(cache_dir, ets_path)

    :ok
  end
  
  @doc """
  Cleans up open file handles left over from writing to the cached files.
  Also generates a partition manifest file signifying the initial pass 
  has been completed
  """

  @spec cleanup(binary, map) :: :ok
  def cleanup(cache_dir, %{} = key_file_map) do

    # Close partition files from file_map
    key_file_map |> Enum.each(fn {_key, pid} ->
      :ok = File.close(pid)
    end)


    # Create manifest file to signal flow initial processing is finished
    manifest_path = cache_dir <> @manifest_file_name

    # 'Touch' manifest file
    # Future could have checksums of each partitioned file, etc..

    _ = case File.exists?(manifest_path) do
      true -> :ok
      false -> :ok = File.touch(manifest_path)
    end

    :ok
  end


end


