defmodule Hangman.Dictionary.Ingestion do

  @moduledoc """
  Module handles the ingestion of hangman dictionary words
  through the coordination of `Ingestion.Flow` and `Ingestion.Cache.Flow`

  Module transforms the dictionary file in two steps

  a) a preprocessing step, which ingests the dictionary file and
  generates ingestion cache partition files

  b) ingestion of cache files into ETS

  For the first step, we run flow and store the results
  in partitioned files.  We pass a map of file_pids keyed by word length key, to 
  facilitate writing to the intermediate partition files

  For subsequent runs with the dictionary file, we simply run flow on the cached 
  output files (the intermediate partition files) saving the initial flow intermediary 
  processing -- windowing etc.  Allowing us to generate and load the relevant data 
  (word list chunks, random word generation, tally generation) into ETS concurrently.
  """

  alias Hangman.{Dictionary, Ingestion}

  # Standard name for hangman dictionary file
  # To distinguish between types, we place file in different directory
  # with directory name marking the difference e.g. "big"
  @dictionary_file_name "words.txt"

  # Partition
  @partition_dir "partition/"
  @partition_file_prefix "words_key_"
  @partition_file_suffix ".txt"

  # Manifest file existance indicates initial flow pass has been completed
  @manifest_file_name "manifest"


  @doc """
  Routine kicks off the ingestion process by 
  setting up the proper state and then running it
  """



  @spec run(Keyword.t) :: :ok
  def run(args) do

    case Dictionary.startup_params(args) do
      {_dir, false} -> :ok # if ingestion is not enabled return :ok

      {dir, true} ->
        dictionary_path = dir <> @dictionary_file_name
        partition_full_dir = dir <> @partition_dir

        setup(dictionary_path, partition_full_dir) |> process

        :ok
    end
  end


  @doc """
  Loads environment to run initial ingestion pass through the dictionary file.
  If this is the first time through, we set up intermediary ingestion cache files
  If not, we ensure the partition manifest file is present indicating the initial
  run is complete and execute the cache ingestion run loading chunks and generating 
  random words into ETS as well as generating tally data
  """

  @spec setup(binary, binary) :: {atom, binary, binary, map} | {atom, binary}
  def setup(dictionary_path, partition_dir)
  when is_binary(dictionary_path) and is_binary(partition_dir) do

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
    # If not, setup partition file state and setup Flow with writing to partition files

    case File.exists?(partition_dir <> @manifest_file_name) do
      false -> 
        # Manifest file doesn't exist -> we haven't partitioned into files yet
        
        # Setup the partition file state
        # Remove the partition dir + files in case it exists cleaning any prior state

        # NOTE: SAFE TO USE RM_RF SINCE WE DON"T ASK FOR USER INPUT INVOLVING PATHS
        # ALL COMPILE-TIME STATIC PATHS
        File.rm_rf!(partition_dir) 
        
        # Start clean with a new partition dir
        File.mkdir!(partition_dir)
        
        # Take a range of key values, and generate a map which contain k-v parts, where
        # the key is the word length, and values are open file pids
        
        # This map will be used when doing the partition each - file write in the 
        # context of the flow processing

        partial_name = partition_dir <> @partition_file_prefix  
      
        key_file_map = Dictionary.key_range |> Enum.reduce(%{}, fn key, acc ->
          file_name = partial_name <> "#{key}" <> @partition_file_suffix

          {:ok, pid} = File.open(file_name, [:append])
          Map.put(acc, key, pid)
        end)
        
        {:ingestion_full, dictionary_path, partition_dir, key_file_map}

      true -> {:ingestion_cache, partition_dir}
    end

  end
  
  @doc """
  Process method supports two modes: full and cache

  `Full` runs the full ingestion process by first
  running the initial ingestion flow process followed by 
  a state cleanup, then running the ingestion cache flow process

  The initial ingestion concurrently chunks the original dictionary
  file into key based partition files which contain the various
  windowed data

  `Cache` runs a flow against the cached partitioned files and 
  concurrently generates and loads all the relevent information into
  memory
  """

  @spec process({atom, binary} | {atom, binary, binary, map}) :: :ok
  def process({:ingestion_full, dictionary_path, partition_dir, 
               %{} = key_file_map}) do

    Ingestion.Flow.run(dictionary_path, key_file_map)
    cleanup(partition_dir, key_file_map)

    Ingestion.Cache.Flow.run(partition_dir)
    :ok
  end

  def process({:ingestion_cache, partition_dir}) do
    Ingestion.Cache.Flow.run(partition_dir)
    :ok
  end
  
  @doc """
  Cleans up open file handles left over from writing to the cached files.
  Also generates a partition manifest file signifying the initial pass 
  has been completed
  """

  @spec cleanup(binary, map) :: :ok
  def cleanup(partition_dir, %{} = key_file_map) do

    # Close partition files from file_map
    key_file_map |> Enum.each(fn {_key, pid} ->
      :ok = File.close(pid)
    end)


    # Create manifest file to signal flow initial processing is finished
    manifest_path = partition_dir <> @manifest_file_name

    # Write manifest file
    # For now we just put :ok into file
    # But for future, 
    # it could be populated with the checksums of each partitioned file, etc..

    case File.exists?(manifest_path) do
      true -> :ok
      false -> File.touch(manifest_path)
    end
  end

  :ok
end


