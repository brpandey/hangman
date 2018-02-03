defmodule Hangman.Dictionary.ETS.Test do
  use ExUnit.Case

  alias Hangman.{Counter, Dictionary, Words}

  # Run before all tests
  setup_all do
    # stop cache server started by application callback
    Application.stop(:hangman_game)
    IO.puts("Dictionary ETS Test")
  end

  # Run before each test
  setup do
    # Start up ETS in a separate process

    {:ok, pid} = Agent.start_link(fn -> Dictionary.ETS.new() end)

    on_exit(fn ->
      # Ensure the dictionary is shutdown with non-normal reason
      Process.exit(pid, :shutdown)

      # Wait until the server is dead
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end)

    {:ok, [agent: pid]}
  end

  describe "types mismatch insertions" do
    test "words-counter types mismatch insertions", %{agent: agent} do
      data = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"]

      # Put list into counter

      Agent.get(agent, fn _tab ->
        assert :function_clause = catch_error(Dictionary.ETS.put(:counter, {5, data}))
      end)
    end

    test "counter-words types mismatch insertions", %{agent: agent} do
      # Put counter into data
      counter = Counter.new([{"a", 12}, {"b", 4}])

      Agent.get(agent, fn _tab ->
        assert :function_clause == catch_error(Dictionary.ETS.put(:words, {5, counter}))
      end)
    end

    test "counter-random types mismatch insertions", %{agent: agent} do
      # Put counter into random
      counter = Counter.new([{"x", 67}, {"y", 98}])

      Agent.get(agent, fn _tab ->
        assert :function_clause = catch_error(Dictionary.ETS.put(:random, {5, counter}))
      end)
    end
  end

  describe "ETS tally insertion and retrieval" do
    test "retrieval without insertion, assert error", %{agent: agent} do
      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.get(:counter, 8)
               end)
    end

    test "proper retrieval after proper insertion", %{agent: agent} do
      data = Counter.new([{"a", 12}, {"b", 4}])

      lookup =
        Agent.get(agent, fn _tab ->
          Dictionary.ETS.put(:counter, {8, data})
          Dictionary.ETS.get(:counter, 8)
        end)

      assert Counter.equal?(lookup, data)
    end

    test "improper retrieval", %{agent: agent} do
      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.get(:counter, 888)
               end)
    end

    test "improper insertion", %{agent: agent} do
      data = Counter.new([{"a", 12}, {"b", 4}])

      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.put(:counter, {888, data})
               end)
    end
  end

  describe "ETS words insertion and retrieval" do
    test "retrieval without insertion, assert empty words", %{agent: agent} do
      assert Words.new(8) ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.get(:words, 8)
               end)
    end

    test "proper retrieval after proper insertion", %{agent: agent} do
      data = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"]

      lookup =
        Agent.get(agent, fn _tab ->
          Dictionary.ETS.put(:words, {5, data})
          Dictionary.ETS.get(:words, 5)
        end)

      assert ^data = lookup |> Words.collect(10) |> Enum.reverse()
    end

    test "proper retrieval after proper multiple insertions", %{agent: agent} do
      data = [
        data_a = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"],
        data_b = ["assay", "assai", "aspis", "aspic", "asper", "aspen", "askos", "askoi", "askew"],
        data_c = [
          "anele",
          "anear",
          "ancon",
          "antes",
          "anted",
          "antas",
          "antae",
          "ansae",
          "anomy",
          "anole",
          "anode"
        ]
      ]

      lookup =
        Agent.get(agent, fn _tab ->
          Dictionary.ETS.put(:words, {5, data_a})
          Dictionary.ETS.put(:words, {5, data_b})
          Dictionary.ETS.put(:words, {5, data_c})
          Dictionary.ETS.get(:words, 5)
        end)

      # The combined data lists should be the same

      assert data |> List.flatten() |> Enum.sort() == lookup |> Words.collect(100) |> Enum.sort()
    end

    test "improper retrieval", %{agent: agent} do
      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.get(:words, 555)
               end)
    end

    test "improper insertion", %{agent: agent} do
      data = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"]

      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.put(:words, {555, data})
               end)
    end
  end

  describe "ETS random words insertion and retrieval" do
    test "retrieval without insertion, assert error", %{agent: agent} do
      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.get(:random, 8)
               end)
    end

    test "proper retrieval after proper insertion", %{agent: agent} do
      data = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"]

      randoms =
        Agent.get(agent, fn _tab ->
          Dictionary.ETS.put(:random, {5, data})
          Dictionary.ETS.get(:random, 5)
        end)

      # Each randoms element should reside within the original data list
      Enum.each(randoms, fn x ->
        assert true = Enum.member?(data, x)
      end)
    end

    test "proper retrieval after proper multiple insertions", %{agent: agent} do
      data = [
        data_a = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"],
        data_b = ["assay", "assai", "aspis", "aspic", "asper", "aspen", "askos", "askoi", "askew"],
        data_c = [
          "anele",
          "anear",
          "ancon",
          "antes",
          "anted",
          "antas",
          "antae",
          "ansae",
          "anomy",
          "anole",
          "anode"
        ]
      ]

      randoms =
        Agent.get(agent, fn _tab ->
          Dictionary.ETS.put(:random, {5, data_a})
          Dictionary.ETS.put(:random, {5, data_b})
          Dictionary.ETS.put(:random, {5, data_c})
          Dictionary.ETS.get(:random, 5)
        end)

      # the randoms list words should be a subset of the combined data list

      data = List.flatten(data)

      Enum.each(randoms, fn x ->
        assert true = Enum.member?(data, x)
      end)
    end

    test "improper retrieval", %{agent: agent} do
      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.get(:random, 555)
               end)
    end

    test "improper insertion", %{agent: agent} do
      data = ["atoms", "atoll", "atmas", "atman", "atlas", "atilt", "ataxy"]

      assert :error ==
               Agent.get(agent, fn _tab ->
                 Dictionary.ETS.put(:random, {555, data})
               end)
    end
  end

  describe "ETS load and dump" do
    test "ETS load file that is not present assert error", %{agent: _agent} do
      path = Path.absname("wakawaka736.txt", :code.priv_dir(:hangman_game))

      # Start load ETS agent
      {:ok, _load} =
        Agent.start_link(fn ->
          assert %HangmanError{} = catch_error(Dictionary.ETS.load(path))
        end)
    end

    test "ETS dump to file and then load properly", %{agent: agent} do
      counter = Counter.new([{"a", 12}, {"b", 4}])

      path = Path.absname("wakawaka737.txt", :code.priv_dir(:hangman_game))

      # dump ETS table to file
      Agent.get(agent, fn _tab ->
        Dictionary.ETS.put(:counter, {5, counter})
        Dictionary.ETS.dump(path)
      end)

      # Stop dump ETS agent
      Agent.stop(agent)

      # Start load of ETS agent
      {:ok, load} = Agent.start_link(fn -> Dictionary.ETS.load(path) end)

      # Data should match
      loaded_counter =
        Agent.get(load, fn _tab ->
          Dictionary.ETS.get(:counter, 5)
        end)

      assert Counter.equal?(counter, loaded_counter)

      # Stop load ETS agent
      Agent.stop(load)

      # Cleanup tmp file
      File.rm(path)
    end
  end
end
