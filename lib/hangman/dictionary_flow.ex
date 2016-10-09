defmodule Dictionary.Flow do
  alias Experimental.Flow


  @num_stages 27


  @root_path "/home/bibek/Workspace/elixir-hangman/priv/"    
  @dictionary_path "#{@root_path}/dictionary/regular/"
  @dictionary_file "words.txt"
  
  @partition_path "#{@dictionary_path}/partition/"
  @manifest_file "manifest.txt"
  @partition_file "words_key_"


  # Dictionary Flow transforms the original dictionary file into a format suitable 

  # a) initially for a flow cache setup 
  # b) flow cache loading into ETS

  # For the first flow run with the dictionary file, we run flow and store the results
  # in partitioned files.  We pass a map of file_pids keyed by word length key, to 
  # facilitate writing to the intermediate partition files

  # For subsequent flow runs with the dictionary file, we simply run flow on the cached 
  # output files (the intermediate partition files) saving the flow intermediary 
  # processing -- windowing etc...  Allowing us to simply load the file data into ETS 
  # without hassling with any post - processing

  def main() do
    setup |> run |> cleanup
  end

  # path = "/home/bibek/Workspace/elixir-hangman/priv/dictionary/regular/partition/words_key_"

  def setup do

    # Check to see if dictionary path is valid, if not error
    case File.exists?(@dictionary_path <> @dictionary_file) do
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

    case File.exists?(@partition_path <> @manifest_file) do

      false -> 
        # Manifest file doesn't exist -> we haven't partitioned into files yet

        # Setup the partition file state
        # Remove the partition dir + files in case it exists 
        # so we don't have any prior state
        File.rm_rf!(@partition_path)
        
        # Start clean with a new partition dir
        File.mkdir!(@partition_path)

        # Take a range of key values, and generate a map which contain k-v paris, where
        # the key is the word length, and values are open file pids

        # This map will be used when doing the partition each - file write in the 
        # context of the flow processing

        partial_name = @partition_path <> @partition_file  
      
        key_file_map = 2..28 |> Enum.reduce(%{}, fn key, acc ->
          file_name = partial_name <> "#{key}"
          IO.puts "file name is : #{inspect file_name}"
          {:ok, pid} = File.open(file_name, [:append])
          Map.put(acc, key, pid)
        end)
        
        {:flow_initial, @dictionary_path <> @dictionary_file, key_file_map}

      true -> 
        {:flow_cache, @partition_path <> @partition_file} # calls Dictionary.Flow.Cache.run
    end

  end
  


  def run({:flow_cache, path}) when is_binary(path) do

    #Dictionary.Flow.Cache.run(path)
    :ok
  end

  def run({:flow_initial, path, %{} = key_file_map}) when is_binary(path) do

    # Basically we want checkpoint snapshots of 1000 events for each partition

    # If we don't use window triggers and lump all the events per partition
    # we have a grouping such as so

    # This means key 8 for example has 28,558 words

    _ = """

    [{12, 11382}, {14, 5134}, {8, 28558}, {15, 3198}, {17, 1125}, {2, 96}, 
    {3, 978}, {27, 2}, {9, 25011}, {10, 20404}, {11, 15581}, {13, 7835}, 
    {4, 3919}, {5, 8672}, {6, 15290}, {7, 23208}, {16, 1938}, {18, 594}, 
    {19, 328}, {20, 159}, {21, 62}, {22, 29}, {23, 13}, {24, 9}, {25, 2},]{28, 1}]


    Now, we use Triggers to process the words in fixed sized containers

    Here's an example of the words organized into 1000 event buckets for each
    partition key (which is roughly the word length key) 


    [{8, 1000}, {9, 1000}, {10, 1000}, {7, 1000}, {11, 1000}, {6, 1000}, {8, 1000}, 
    {9, 1000}]

    So key 8 - partition 6 - already has two sets of 1000 events
    
    Here's an example of the words corresponding to above
    
    [%{8 => ["antinuke", "antinomy", "antinode", "antimony", "antimere", "antimask", "antimale", "antilogy", "antilogs", "antilock", "antilife", "antileft", "antileak", "antiking", "antihero", "antigens", "antigene", "antifoam", "antidrug", "antidote", "antidora", ...]}, %{9 => ["antiwhite", "antivirus", "antiviral", "antivenin", "antiurban", "antiunion", "antiulcer", "antitypes", "antitumor", "antitrust", "antitoxin", "antitoxic", "antitheft", "antistory", "antistick", "antistate", "antisolar", "antismoke",  ...]}, %{10 => ["areologies", "arenaceous", "arecolines", "arctically", "arctangent", "archpriest", "archosaurs", "archnesses", "archivolts", "archivists", "architrave", "architects", "archfiends", "archetypes", ...]}, %{7 => ["artisan", "artiest", "article", "arsines", "arshins", "arsenic", "arsenal", "arroyos", "arrowed", "arrobas", "arrives", "arriver",  ...]}, %{11 => ["autoloading", "autographic", "autographed", "autografted", "autoerotism", "autodidacts", "autocrosses", "autocracies", "autoclaving", "autochthons", "autocephaly", "authorships", "authorizing", "authorizers", "authorities", ...]}, %{6 => ["batboy", "bastes", "baster", "basted", "bassos", "bassly", "basset", "basses", "basque", "basket", "basked", "basion", "basins", "basing", "basils", "basify", "basics", "bashes", "basher", "bashed", "bashaw", "basest", ...]}, %{8 => ["bearskin", "bearlike", "bearings", "bearhugs", "bearding", "bearcats", "bearably", "bearable", "beanpole", "beanlike", "beanball", "beanbags", "beamlike", "beamless", "beamiest", "beaklike", ...]}, %{9 => ["beflagged", "befitting", ...]},

    """

    # By setting the trigger, the reduce function
    # is checkpointed every 1000 events
    window = Flow.Window.global |> Flow.Window.trigger_every(1000, :reset)

    File.stream!(path, read_ahead: 100_000)
    |> Flow.from_enumerable()
    |> Flow.map(&event_map/1)
    |> Flow.partition(window: window, stages: @num_stages, hash: &event_route/1)
    |> Flow.reduce(fn -> %{} end, &partition_reduce/2)
    |> Flow.each_state(fn state -> partition_each(state, key_file_map) end)
#    |> Flow.emit(:state)
    |> Flow.run

#    IO.puts "Result is #{inspect result}"

    {:ok, key_file_map}
  end



  ###################################
  #  START - FLOW HELPER FUNCTIONS
  ###################################

  # Maps each event in parallel to a tuple event
  defp event_map(event) when is_binary(event) do
    event = event |> String.trim |> String.downcase
    {String.length(event), event}    
  end


  # Caclulate the partition hash for the event using the event_route function
  # which returns partition to route the event to
  defp event_route({key, word}) when is_integer(key) and is_binary(word) do

    # If we have key lengths ranging from 2..28 we have 27 partitions
    # So for example, given a key of length 7 this would go into
    # 7 - 2 => partition 5 (we account for 0 based partition scheme and that we start at 2, hence -2)
    # remainder(7 -2, 27)

    # So word of length 2 would go into partition 0, 
    # length 3 goes to partition 1, etc..
    # 28 goes to partition 26

    {{key, word}, rem(key - 2, @num_stages)}
  end


  # Reduce the partition data given the window trigger of 1000 events
  # The acc state is reset after the trigger is materialized
  # The reduce is run per window partition 
  defp partition_reduce({key, word}, %{} = acc) do
#      IO.puts "key is #{key}, word is #{word}"
      Map.update(acc, key, [word], &([word] ++ &1))
  end

  # Invoked after partition reduce
  # Apply function to each partition's state which is a map

  defp partition_each(%{} = acc_map, %{} = key_file_map) do

    # Only one key value in each partition map state
    case Map.to_list(acc_map) do
      [] -> ""
      [{k, v}] -> 
        IO.puts "map_state result: #{inspect {k, Enum.count(v)}}"

        # retrieve file pid and write partition data to file
        file_pid = Map.get(key_file_map, k)

        IO.write(file_pid, "#{k}: #{Enum.join(v, ", ")}")
        # Add delimiter after every chunk, easier for chunk retrieval
        IO.write(file_pid, "    \n")
    end

    :ok
  end


  ###################################
  #  END - FLOW HELPER FUNCTIONS
  ###################################


  def cleanup(:ok), do: :ok

  def cleanup({:ok, %{} = key_file_map}) do

    # close partition files from file_map
    key_file_map |> Enum.each(fn {_key, pid} ->
      :ok = File.close(pid)
    end)


    # Create manifest file to signal flow initial processing is finished

    manifest_path = @partition_path <> @manifest_file

    # Write manifest file
    # For now we just put :ok into file
    # But for future, 
    # it could be populated with the checksums of each partitioned file, etc..

    case File.exists?(manifest_path) do
      true -> :ok
      false -> File.touch(manifest_path)
    end

  end



end


