defmodule Dictionary.Flow do
  alias Experimental.Flow


  @num_stages 27

  def run do

    root_path = "/home/bibek/Workspace/elixir-hangman/priv"    
    path = "#{root_path}/dictionary/data/words.txt"


    # Basically we want checkpoint snapshots of 1000 events for each partition

    # If we don't use window triggers and lump all the events per partition
    # we have a grouping such as so

    # This means key 8 for example has 28,558 words

    _ = """

    [{12, 11382}, {14, 5134}, {8, 28558}, {15, 3198}, {17, 1125}, {2, 96}, 
    {3, 978}, {27, 2}, {9, 25011}, {10, 20404}, {11, 15581}, {13, 7835}, 
    {4, 3919}, {5, 8672}, {6, 15290}, {7, 23208}, {16, 1938}, {18, 594}, 
    {19, 328}, {20, 159}, {21, 62}, {22, 29}, {23, 13}, {24, 9}, {25, 2},]{28, 1}]


    ==> So we use Triggers! to process the words in fixed sized containers

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


    File.stream!(path)
    |> Flow.from_enumerable()
    |> Flow.map(&event_map/1)
    |> Flow.partition(window: window, stages: @num_stages, hash: &event_route/1)
    |> Flow.reduce(fn -> %{} end, &partition_reduce/2)
    |> Flow.each_state(&partition_each/1)
#    |> Flow.emit(:state)
    |> Flow.run

#    IO.puts "Result is #{inspect result}"
  end


  # Map each event into a tuple event
  def event_map(event) when is_binary(event) do
    event = event |> String.trim |> String.downcase
    {String.length(event), event}    
  end


  # caclulate the partition hash for the event using the event_route function
  # which returns partition to route the event to
  def event_route({key, word}) when is_integer(key) and is_binary(word) do

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
  # The reduce is implement per window partition
  def partition_reduce({key, word}, %{} = acc) do
#      IO.puts "key is #{key}, word is #{word}"
      Map.update(acc, key, [word], &([word] ++ &1))
  end

  # Invoked after partition reduce
  # Apply function to each partition's state which is a map

  def partition_each(%{} = map) do

    # Only one key value in each partition map state
    case Map.to_list(map) do
      [] -> ""
      [{_k, _v}] -> 
        IO.puts "map_state result: #{inspect map_size(map)}"
    end

    #      |> Enum.reduce([], fn {key, words}, acc ->
    #        [{key, Enum.count(words)}] ++ acc
    #      end)

    :ok
  end

end


