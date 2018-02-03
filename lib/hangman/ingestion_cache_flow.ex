defmodule Hangman.Ingestion.Cache.Flow do
  @moduledoc """
  Loads partitioned dictionary word files into ingestion table
  piecewise through words list chunks.  Random words are generated
  from these words lists.

  Letter frequency counters of the dictionary words 
  are arranged by length and also stored in the ingestion db after the 
  words are stored

  Optimization Note 1: Generating counter tallies outside of 
  the ingestion table allows us to use Flow's parallelism to generate these

  Optimization Note 2: Converting word_list chunks to binaries
  and counters to binaries drastically reduces table memory footprint
  """

  alias Experimental.Flow
  alias Hangman.{Counter, Dictionary}
  require Logger

  @doc """
  Loads up the intermediate cached files and processes the data
  using flow so that it can be stored in a table. The types of data
  generated and stored into the db are words data, random words, and 
  letter frequency counters arranged by word key length.

  Lastly, the ingestion db is dumped to file
  """

  @spec run(binary, binary) :: :ok
  def run(cache_dir, dump_path)
      when is_binary(cache_dir) and is_binary(dump_path) do
    streams =
      for file <- File.ls!(cache_dir) do
        case String.ends_with?(file, ".txt") do
          true -> File.stream!("#{cache_dir}/#{file}", read_ahead: 100_000)
          false -> nil
        end
      end

    # Filter out the stream items that aren't nil
    streams = Enum.filter(streams, fn x -> x != nil end)

    # The flow logic allows us to insert the word lists and random values in parallel (event reduce)
    # The counter generation is also done in parallel, with the final counter insert
    # performed in the final reduce

    # Plural for multiple streams
    # Use the word length key when doing the hash
    streams
    |> Flow.from_enumerables()
    |> Flow.map(&event_map/1)
    |> Flow.partition(key: {:elem, 0})
    |> Flow.reduce(fn -> %{} end, &event_reduce/2)
    |> Flow.departition(
      &Map.new/0,
      # for key collisions merge Counters
      &Map.merge(&1, &2, fn _, v1, v2 -> Counter.merge(v1, v2) end),
      &final_reduce/1
    )
    |> Flow.run()

    dump_path |> Dictionary.Ingestion.dump()

    :ok
  end

  # Event is a cache file line up to new line
  # The function splits it first into a line without the delimiter 
  # and then into the word length key and the words data

  @spec event_map(binary) :: {pos_integer, [binary]}
  defp event_map(event) do
    kv_delim = Dictionary.Ingestion.delimiter(:kv)
    line_delim = Dictionary.Ingestion.delimiter(:line)

    [k, v] =
      event
      |> String.split(line_delim, trim: true)
      |> List.first()
      |> String.split(kv_delim)

    key = k |> String.to_integer()
    value = v |> String.split(", ", trim: true)

    {key, value}
  end

  # Event reduce performs three tasks
  # -Reduce the word length key and words lists into the table
  # -Generate random words as well into the ingestion db
  # -Build up the counter object in the meantime

  @spec event_reduce({pos_integer, [binary, ...]}, map) :: map
  defp event_reduce({k, v}, %{} = counter_map)
       when is_integer(k) and is_list(v) and is_binary(hd(v)) do
    Dictionary.Ingestion.put(:words, {k, v})
    Dictionary.Ingestion.put(:random, {k, v})

    Dictionary.Ingestion.print_table_info()

    # Create a simple counter object representing 
    # the letter tally of the word list
    counter = Counter.new() |> Counter.add_words(v)

    # If a counter value doesn't exist yet for the 
    # word length key, simply add the counter

    # If a counter value does exist, simply merge the two counters together
    counter_map = Map.update(counter_map, k, counter, &Counter.merge(&1, counter))

    _ =
      Logger.debug(
        "partition reduce: key #{k}, counter_map keys are #{inspect(Map.keys(counter_map))}"
      )

    counter_map
  end

  # Take the final acc, namely the counter map here and
  # insert it into the db

  @spec final_reduce(map) :: :ok
  defp final_reduce(%{} = counter_map) do
    # Store the counters by key into the ingestion db
    Enum.reduce(counter_map, [], fn {k, c}, _acc ->
      Dictionary.Ingestion.put(:counter, {k, c})
    end)

    :ok
  end
end
