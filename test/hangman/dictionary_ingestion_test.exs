defmodule Hangman.Dictionary.Ingestion.Test do
  # , async: true since the ets table name is unique
  use ExUnit.Case

  alias Hangman.{Dictionary, Counter, Words}

  # Run before all tests
  setup_all do
    # stop cache server started by application callback
    Application.stop(:hangman_game)
    IO.puts("Dictionary Ingestion Test")

    # initialize params map for test cases
    # each test just needs to grab the current player id

    # NOTE: only including regular dictionary since it is faster
    #       faster test only for now

    # Dictionary.start_link keyword params

    map = %{
      :regular_full => [type: :regular, ingestion: true],
      :regular_partial => [type: :regular, ingestion: true],
      # don't run ingestion
      :regular_abort => [type: :regular, ingestion: false]
    }

    {:ok, params: map}
  end

  # Run before each test
  setup context do
    map = context[:params]
    case_key = context[:case_key]
    args = Map.get(map, case_key)

    # To ensure we trigger the appropriate types of ingestion
    # we remove the appropriate file(s)

    case case_key do
      :regular_partial -> remove_ets(args)
      :regular_full -> remove_manifest_and_ets(args)
      :regular_abort -> :ok
    end

    # Start up dictionary cache server

    pid =
      case Dictionary.Cache.start_link(args) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    case case_key do
      :regular_partial -> :ok = check_ingestion_file_structure(args)
      :regular_full -> :ok = check_ingestion_file_structure(args)
      :regular_abort -> :ok
    end

    IO.puts("finished dictionary ingestion setup")

    on_exit(fn ->
      # Ensure the dictionary is shutdown with non-normal reason
      Process.exit(pid, :shutdown)

      # Wait until the server is dead
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end)
  end

  def remove_manifest_and_ets(args) do
    # force the full ingestion

    # remove manifest and ets file and ensure we generate intermediary files
    # as well as load everything correctly into ETS

    remove_manifest(args)
    remove_ets(args)
  end

  def remove_manifest(args) do
    # NOTE: As of now this is not called stand alone

    # force the cache ingestion load

    # remove manifest file and ensure we compute intermediary
    # files (provided there's no ets file)

    dir_path = Dictionary.directory_path(args)
    manifest_file = dir_path <> "cache/manifest"

    File.rm(manifest_file)
  end

  def remove_ets(args) do
    # force the cache ingestion load

    # remove ets file and ensure we compute ets file correctly from
    # intermediary files

    dir_path = Dictionary.directory_path(args)
    ets_file = dir_path <> "cache/ets_table"

    File.rm(ets_file)
  end

  def check_ingestion_file_structure(args) do
    dir_path = Dictionary.directory_path(args)
    {:ok, list} = File.ls(dir_path <> "cache/")

    assert [
             "ets_table",
             "manifest",
             "words_key_10.txt",
             "words_key_11.txt",
             "words_key_12.txt",
             "words_key_13.txt",
             "words_key_14.txt",
             "words_key_15.txt",
             "words_key_16.txt",
             "words_key_17.txt",
             "words_key_18.txt",
             "words_key_19.txt",
             "words_key_2.txt",
             "words_key_20.txt",
             "words_key_21.txt",
             "words_key_22.txt",
             "words_key_23.txt",
             "words_key_24.txt",
             "words_key_25.txt",
             "words_key_26.txt",
             "words_key_27.txt",
             "words_key_28.txt",
             "words_key_3.txt",
             "words_key_4.txt",
             "words_key_5.txt",
             "words_key_6.txt",
             "words_key_7.txt",
             "words_key_8.txt",
             "words_key_9.txt"
           ] = Enum.sort(list)

    :ok
  end

  @tag case_key: :regular_abort
  test "test of regular dictionary with no ingestion, catch no table errors" do
    ensure_regular_not_loaded()
    Dictionary.stop()
  end

  @tag case_key: :regular_full
  test "test of regular dictionary with full ingestion, along with tally and counter lookups to verify" do
    ensure_regular_loaded()
    Dictionary.stop()
  end

  @tag case_key: :regular_partial
  test "test of regular dictionary with cache ingestion, along with tally and counter lookups to verify" do
    ensure_regular_loaded()
    Dictionary.stop()
  end

  def ensure_regular_loaded do
    size = 8

    lookup = Dictionary.lookup(:tally, size)

    counter_8 =
      Counter.new(%{
        "a" => 14490,
        "b" => 4485,
        "c" => 7815,
        "d" => 8046,
        "e" => 19600,
        "f" => 2897,
        "g" => 6009,
        "h" => 5111,
        "i" => 15530,
        "j" => 384,
        "k" => 2628,
        "l" => 11026,
        "m" => 5793,
        "n" => 12186,
        "o" => 11462,
        "p" => 5763,
        "q" => 422,
        "r" => 14211,
        "s" => 16560,
        "t" => 11870,
        "u" => 7377,
        "v" => 2156,
        "w" => 2313,
        "x" => 662,
        "y" => 3395,
        "z" => 783
      })

    assert Counter.equal?(lookup, counter_8)

    words = %Words{} = Dictionary.lookup(:words, 8)

    word_count = 28558

    assert word_count == Words.count(words)
  end

  def ensure_regular_not_loaded do
    # catch errors of non-existent dictionary table

    size = 8

    assert catch_error(Dictionary.lookup(:tally, size)) ==
             %HangmanError{message: "table not loaded yet"}

    assert catch_error(Dictionary.lookup(:words, size)) ==
             %HangmanError{message: "table not loaded yet"}
  end
end
