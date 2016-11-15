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
      :regular_randoms => [type: :regular, ingestion: true],
      :regular_tally_words => [type: :regular, ingestion: true],
      :big_tally_words => [type: :big, ingestion: true]
    }

    {:ok, params: map}
  end

  # Run before each test
  setup context do

    map = context[:params]
    case_key = context[:case_key]
    args = Map.get(map, case_key)

    pid = 
      case Dictionary.Cache.start_link(args) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end


    IO.puts "finished dictionary setup"

    on_exit fn -> 
      # Ensure the dictionary is shutdown with non-normal reason
      Process.exit(pid, :shutdown)

      # Wait until the server is dead
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end
  end


  @tag case_key: :regular_randoms
  test "test of regular dictionary random word lookups" do

    assert catch_error(Dictionary.lookup(:random, 8472)) ==
      %HangmanError{message: "random count exceeds max random words"}

    randoms = Dictionary.lookup(:random, 50)
    assert ^randoms = randoms |> Enum.uniq 

    # Takes 3 secs skipping
    # randoms = Dictionary.lookup(:random, 500)
    # assert ^randoms = randoms |> Enum.uniq 

    Dictionary.stop
  end



  @tag case_key: :regular_tally_words
  test "test of regular dictionary tally and words lookups" do

    size = 8

    assert catch_error(Dictionary.lookup(:tally, 3383)) ==
      %HangmanError{message: "key not in set of possible keys!"}

    lookup = Dictionary.lookup(:tally, size)

    counter_8 = Counter.new(%{"a" => 14490, "b" => 4485, 
      "c" => 7815, "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, 
      "h" => 5111, "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, 
      "m" => 5793, "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, 
      "r" => 14211, "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, 
      "w" => 2313, "x" => 662, "y" => 3395, "z" => 783})

    assert Counter.equal?(lookup, counter_8)


    assert catch_error(Dictionary.lookup(:words, 2775)) ==
      %HangmanError{message: "key not in set of possible keys!"}

    
    words = %Words{} = Dictionary.lookup(:words, 8)

    word_count = 28558

    assert word_count == Words.count(words)    

    Words.stream(words)
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(20)

    Dictionary.stop
  end



  @tag case_key: :big_tally_words  
  test "test of big dictionary tally and words lookup" do

    size = 8

    assert catch_error(Dictionary.lookup(:tally, 3383)) ==
      %HangmanError{message: "key not in set of possible keys!"}

    lookup = Dictionary.lookup(:tally, size)

    counter_big_8 = Counter.new(%{"a" => 31575, "b" => 9147, "c" => 14546, "d" => 14298, "e" => 33942, "f" => 5370, "g" => 10575, "h" => 11748, "i" => 28901, "j" => 1267, "k" => 6898, "l" => 21204, "m" => 12953, "n" => 25202, "o" => 23069, "p" => 9747, "q" => 714, "r" => 26380, "s" => 23083, "t" => 21248, "u" => 14382, "v" => 4257, "w" => 4804, "x" => 1150, "y" => 7307, "z" => 1906})


    assert Counter.equal?(lookup, counter_big_8)


    assert catch_error(Dictionary.lookup(:words, 2775)) ==
      %HangmanError{message: "key not in set of possible keys!"}
    
    words = %Words{} = Dictionary.lookup(:words, 8)

    big_word_count = 54500

    assert big_word_count == Words.count(words)

    Words.stream(words)
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(20)


    Dictionary.stop()
  end



end
