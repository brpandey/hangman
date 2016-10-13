defmodule Hangman.Ingestion.Cache.Flow do

  alias Experimental.Flow

  alias Hangman.{Counter, Dictionary}

  require Logger

  @ets Dictionary.ETS.table_name

  @moduledoc """
  Loads partitioned dictionary word files into ets table
  piecewise through words list chunks.  Random words are generated
  from these words lists.
  
  Letter frequency counters of the dictionary words 
  are arranged by length and also stored in the ets after the 
  chunks are stored

  Optimization Note 1: Generating counter tallies outside of 
  ETS allows us to use Flow's parallelism to generate these

  Optimization Note 2: Converting word_list chunks to binaries
  and counters to binaries drastically reduces ets memory footprint
  """

  def run(cache_dir) when is_binary(cache_dir) do

    # NOTE: The process will own the ets table
    # Since Ingestion.Flow.Cache.run is called from the
    # Dictionary.Cache process this works as desired

    @ets = Dictionary.ETS.new

    streams = for file <- File.ls!(cache_dir) do
      case String.ends_with?(file, ".txt") do
        true -> File.stream!("#{cache_dir}/#{file}", read_ahead: 100_000)
        false -> nil
      end
    end

    # Filter out the stream items that aren't nil
    streams = Enum.filter(streams, fn x -> x != nil end)
    
    # The flow logic allows us to insert the chunks and random values in parallel (event reduce)
    # The counter generation is also done in parallel, with the final counter insert
    # performed in the final reduce

    streams
    |> Flow.from_enumerables() # Plural for multiple streams
    |> Flow.map(&event_map/1)
    |> Flow.partition(hash: {:elem, 0}) # Use the word length key when doing the hash
    |> Flow.reduce(fn -> %{} end, &event_reduce/2)
    |> Flow.departition(
      &Map.new/0, 
      &Map.merge(&1, &2, fn _, v1, v2 -> Counter.merge(v1, v2) end), # for key collisions merge Counters
      &final_reduce/1
    )
    |> Flow.run

  end


  # Event is a partition file line up to new line
  # we split it first into a line that contains the word length key
  # and the words data

  defp event_map(event) do

    [k, v] = event 
    |> String.split("    \n", trim: true) 
    |> List.first 
    |> String.split(": ") 

    key = k |> String.to_integer
    value = v |> String.split(", ", trim: true)

    {key, value}
  end
  

  # Reduce the word length key and words lists into the ets
  # Generate random words as well into the ets
  # Build up the counter object in the meantime

  defp event_reduce({k,v}, %{} = counter_map) 
  when is_integer(k) and is_list(v) and is_binary(hd(v)) do

    ets = @ets
          
    Dictionary.ETS.put(:chunk, ets, {k, v})
    Dictionary.ETS.put(:random, ets, {k, v})
    
    info = :ets.info(ets)
    _ = Logger.debug ":chunks, ets info is: #{inspect info}\n"
    
    # Create a simple counter object representing 
    # the letter tally of the word list
    counter = Counter.new |> Counter.add_words(v)

    # If a counter value doesn't exist yet for the 
    # word length key, simply add the counter

    # If a counter value does exist, simply merge the two counters together
    counter_map = Map.update(counter_map, k, counter, &Counter.merge(&1, counter))

    Logger.debug("ingestion cache flow - partition reduce: key #{k}, counter_map keys are #{inspect Map.keys(counter_map)}")
    
    counter_map
  end

  # Take the final acc, namely the counter map here and
  # insert it into the ets table

  defp final_reduce(%{} = counter_map) do

    ets = @ets

    # Store the counters by key into the ets
    counter_map |> Enum.reduce(ets, fn {k,c}, acc ->
      Dictionary.ETS.put(:counter, acc, {k,c})
      acc
    end)

    info = :ets.info(ets)
    _ = Logger.debug ":counter + chunks, ets info is: #{inspect info}\n"

    :ok
  end
  

end
