defmodule Hangman.Dictionary.Test do
  use ExUnit.Case #, async: true since the ets table name is unique

  alias Hangman.{Dictionary, Counter, Words}

  # Run before all tests
  setup_all do

    # stop cache server started by application callback
    Application.stop(:hangman_game)
    IO.puts "Dictionary Test"

    # initialize params map for test cases
    # each test just needs to grab the current player id
    map = %{
      :regular_full => [type: :regular, ingestion: true],
      :big => [type: :big, ingestion: true]
    }

    {:ok, params: map}
  end

  # Run before each test
  setup context do

    map = context[:params]
    case_key = context[:case_key]
    args = Map.get(map, case_key)

    # To ensure we are doing a full ingestion we remove the manifest and ets file
    if case_key == :regular_full, do: remove_manifest_and_ets(args)

    pid = 
      case Dictionary.Cache.start_link(args) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    if case_key == :regular_full, do: check_partition_structure(args)

    IO.puts "finished dictionary setup"


    on_exit fn -> 
      # Ensure the dictionary is shutdown with non-normal reason
      Process.exit(pid, :shutdown)

      # Wait until the server is dead
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end
  end


  def remove_manifest_and_ets(args) do
    # remove manifest and ets file and ensure we generate intermediary files
    # as well as load everything correctly into ETS

    dir_path = Dictionary.directory_path(args)
    manifest = dir_path <> "cache/manifest"
    ets_file = dir_path <> "cache/ets_table"

    File.rm(manifest)
    File.rm(ets_file)

  end

  def check_partition_structure(args) do
    dir_path = Dictionary.directory_path(args)
    {:ok, list} = File.ls(dir_path <> "cache/")

    assert ["ets_table", "manifest", "words_key_10.txt", "words_key_11.txt", "words_key_12.txt",
            "words_key_13.txt", "words_key_14.txt", "words_key_15.txt", "words_key_16.txt", 
            "words_key_17.txt", "words_key_18.txt", "words_key_19.txt", "words_key_2.txt",
            "words_key_20.txt", "words_key_21.txt", "words_key_22.txt", "words_key_23.txt", 
            "words_key_24.txt", "words_key_25.txt", "words_key_26.txt", "words_key_27.txt", 
            "words_key_28.txt", "words_key_3.txt", "words_key_4.txt", "words_key_5.txt",
            "words_key_6.txt", "words_key_7.txt", "words_key_8.txt", "words_key_9.txt"] = 
      Enum.sort(list)

  end


  @tag case_key: :regular_full
  test "test of regular dictionary, full ingestion" do

    size = 8

#   assert catch_error(Dictionary.Cache.lookup(pid, :tally, 3383)) ==
#     %Hangman.Error{message: "key not in set of possible keys!"}

    lookup = Dictionary.lookup(:tally, size)

    counter_8 = Counter.new(%{"a" => 14490, "b" => 4485, 
      "c" => 7815, "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, 
      "h" => 5111, "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, 
      "m" => 5793, "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, 
      "r" => 14211, "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, 
      "w" => 2313, "x" => 662, "y" => 3395, "z" => 783})

    IO.puts "lookup is: #{inspect lookup}"

    assert Counter.equal?(lookup, counter_8)
    
    IO.puts "Counters match\n\n"
  
    words = %Words{} = Dictionary.lookup(:words, 8)

    word_count = 28558

    assert word_count == Words.count(words)    

    IO.puts "words: #{inspect words}"

    randoms = Dictionary.lookup(:random, 10)
    IO.puts "random hangman words 1: #{inspect randoms}"

    randoms = Dictionary.lookup(:random, 10)
    IO.puts "random hangman words 2: #{inspect randoms}"

    randoms = Dictionary.lookup(:random, 10)
    IO.puts "random hangman words 3: #{inspect randoms}"


    Words.stream(words)
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(20)


    Dictionary.stop
  end



  @tag case_key: :big  
  test "test of big dictionary ingestion" do


    size = 8

#   assert catch_error(Dictionary.lookup(:tally, 3383)) ==
#     %RuntimeError{message: "key not in set of possible keys!"}

    lookup = Dictionary.lookup(:tally, size)

    counter_big_8 = Counter.new(%{"a" => 31575, "b" => 9147, "c" => 14546, "d" => 14298, "e" => 33942, "f" => 5370, "g" => 10575, "h" => 11748, "i" => 28901, "j" => 1267, "k" => 6898, "l" => 21204, "m" => 12953, "n" => 25202, "o" => 23069, "p" => 9747, "q" => 714, "r" => 26380, "s" => 23083, "t" => 21248, "u" => 14382, "v" => 4257, "w" => 4804, "x" => 1150, "y" => 7307, "z" => 1906})


    IO.puts "lookup is: #{inspect lookup}"

    assert Counter.equal?(lookup, counter_big_8)
    
    IO.puts "Counters match\n\n"
  
    words = %Words{} = Dictionary.lookup(:words, 8)

    big_word_count = 54500

    assert big_word_count == Words.count(words)

    IO.puts "words: #{inspect words}"

    randoms = Dictionary.lookup(:random, 10)
    IO.puts "random hangman words 1: #{inspect randoms}"

    randoms = Dictionary.lookup(:random, 10)
    IO.puts "random hangman words 2: #{inspect randoms}"

    randoms = Dictionary.lookup(:random, 10)
    IO.puts "random hangman words 3: #{inspect randoms}"


    Words.stream(words)
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(20)


    Dictionary.stop()
  end



end
