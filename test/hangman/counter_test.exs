defmodule Hangman.Counter.Test do
  use ExUnit.Case, async: true

  alias Hangman.Counter, as: Counter

  setup_all do
    IO.puts("Counter Test")
    :ok
  end

  describe "counter create" do
    test "create with string" do
      pattern = "A-OCA-O"

      assert [{"-", 2}, {"A", 2}, {"C", 1}, {"O", 2}] =
               pattern |> Counter.new() |> Counter.items()
    end

    test "create with empty string" do
      pattern = ""

      assert [] = pattern |> Counter.new() |> Counter.items()
    end

    test "create with tuple list" do
      list = [{"O", 3}, {"A", 2}, {"E", 2}]
      tally = list |> Counter.new() |> Counter.inc_by("E", 5)

      assert [{"E", 7}, {"O", 3}, {"A", 2}] = tally |> Counter.most_common(10)
    end

    test "create with empty tuple list" do
      list = []
      assert [] = list |> Counter.new() |> Counter.items()
    end

    test "create with map" do
      map = %{
        "i" => 43,
        "o" => 42,
        "u" => 40,
        "l" => 35,
        "c" => 29,
        "n" => 27,
        "r" => 24,
        "s" => 20,
        "m" => 17,
        "b" => 15,
        "p" => 13,
        "d" => 12,
        "h" => 9,
        "g" => 9,
        "v" => 6,
        "f" => 6,
        "j" => 3,
        "y" => 2,
        "k" => 2,
        "x" => 1,
        "z" => 1,
        "w" => 1
      }

      assert [{"i", 43}, {"o", 42}, {"u", 40}] = map |> Counter.new() |> Counter.most_common(3)

      assert [
               {"b", 15},
               {"c", 29},
               {"d", 12},
               {"f", 6},
               {"g", 9},
               {"h", 9},
               {"i", 43},
               {"j", 3},
               {"k", 2},
               {"l", 35},
               {"m", 17},
               {"n", 27},
               {"o", 42},
               {"p", 13},
               {"r", 24},
               {"s", 20},
               {"u", 40},
               {"v", 6},
               {"w", 1},
               {"x", 1},
               {"y", 2},
               {"z", 1}
             ] = map |> Counter.new() |> Counter.items()
    end

    test "create with empty map" do
      map = %{}
      assert [] = map |> Counter.new() |> Counter.items()
    end
  end

  describe "counter read operations" do
    test "check empty with non-empty" do
      pattern = "A-OCA-O"
      assert false == pattern |> Counter.new() |> Counter.empty?()
    end

    test "check empty with empty" do
      pattern = ""
      assert true == pattern |> Counter.new() |> Counter.empty?()
    end

    test "equals with differing case" do
      tally1 = [{"O", 3}, {"A", 2}, {"E", 2}] |> Counter.new()
      tally2 = [{"o", 3}, {"a", 2}, {"e", 2}] |> Counter.new()

      assert false == Counter.equal?(tally1, tally2)

      tally1 = "BON JOUR" |> Counter.new()
      tally2 = "bon jour" |> Counter.new()

      assert false == Counter.equal?(tally1, tally2)
    end

    test "equals with same case, same content" do
      tally1 = [{"O", 3}, {"A", 2}, {"E", 2}] |> Counter.new()
      tally2 = [{"O", 3}, {"A", 2}, {"E", 2}] |> Counter.new()

      assert Counter.equal?(tally1, tally2)

      tally1 = "BON JOUR" |> Counter.new()
      tally2 = "BON JOUR" |> Counter.new()

      assert Counter.equal?(tally1, tally2)
    end

    test "most common empty counter" do
      assert [] = Counter.new() |> Counter.most_common(5)
      assert [] = [] |> Counter.new() |> Counter.most_common(5)

      assert [] = Counter.new() |> Counter.most_common_key(5)
      assert [] = [] |> Counter.new() |> Counter.most_common_key(5)
    end

    test "most common non-empty counter" do
      assert [{"-", 6}, {"a", 3}, {"x", 1}] =
               "a---ax---a" |> Counter.new() |> Counter.most_common(5)

      assert ["-", "a", "x"] = "a---ax---a" |> Counter.new() |> Counter.most_common_key(5)

      assert [{"-", 9}, {"a", 3}] = "-x--a---a---a" |> Counter.new() |> Counter.most_common(2)

      assert ["-", "a"] = "-x--a---a---a" |> Counter.new() |> Counter.most_common_key(2)

      assert [{"-", 10}] = "---a---a-x--a-" |> Counter.new() |> Counter.most_common(1)

      assert ["-"] = "---a---a-x--a-" |> Counter.new() |> Counter.most_common_key(1)
    end

    test "keys from empty counter" do
      assert [] = Counter.new() |> Counter.keys()
      assert [] = [] |> Counter.new() |> Counter.keys()
    end

    test "keys from non-empty counter" do
      assert [" ", "B", "J", "N", "O", "R", "o", "u"] =
               "BoN JOuR" |> Counter.new() |> Counter.keys()
    end
  end

  describe "counter add operations" do
    test "add unique letters from string and tally" do
      token = "mississippi"
      # 1 "m", 1 "i", 1 "s", 1 "p"
      tally = Counter.new() |> Counter.add_unique_letters(token)

      assert [{"i", 1}, {"m", 1}, {"p", 1}, {"s", 1}] = Counter.most_common(tally, 5)
    end

    test "add non-unique letters from string and tally" do
      token = "mississippi"

      tally =
        Counter.new()
        |> Counter.add_letters(token)
        |> Counter.add_letters([])
        |> Counter.add_letters("")

      assert [{"i", 4}, {"s", 4}, {"p", 2}, {"m", 1}] = tally |> Counter.most_common(5)

      assert [{"i", 4}, {"m", 1}, {"p", 2}, {"s", 4}] = tally |> Counter.items()
    end

    test "add non-unique letters from codepoints list and tally" do
      token = "mississippi"
      codepoints = token |> String.codepoints()

      tally =
        Counter.new()
        |> Counter.add_letters("")
        |> Counter.add_letters([])
        |> Counter.add_letters(codepoints)

      assert [{"i", 4}, {"s", 4}, {"p", 2}, {"m", 1}] = tally |> Counter.most_common(5)

      assert [{"i", 4}, {"m", 1}, {"p", 2}, {"s", 4}] = tally |> Counter.items()
    end

    test "add words list" do
      word_list = [
        "cotoneaster",
        "cotransduce",
        "cotransfers",
        "cotransport",
        "cottonmouth",
        "cottonseeds",
        "cottontails",
        "cottonweeds",
        "cottonwoods",
        "cotylosaurs",
        "coulometers",
        "coulometric",
        "councillors",
        "counselings",
        "counselling",
        "counsellors",
        "countenance",
        "counteracts",
        "counterbade",
        "counterbids",
        "counterblow",
        "countercoup",
        "counterfeit",
        "counterfire"
      ]

      tally = Counter.new() |> Counter.add_words(word_list)

      assert [
               {"a", 9},
               {"b", 3},
               {"c", 24},
               {"d", 6},
               {"e", 18},
               {"f", 3},
               {"g", 2},
               {"h", 1},
               {"i", 8},
               {"l", 9},
               {"m", 3},
               {"n", 21},
               {"o", 24},
               {"p", 2},
               {"r", 16},
               {"s", 16},
               {"t", 20},
               {"u", 17},
               {"w", 3},
               {"y", 1}
             ] = tally |> Counter.items()
    end

    test "add words list stream with exclusion" do
      list = [
        "cotoneaster",
        "cotransduce",
        "cotransfers",
        "cotransport",
        "cottonmouth",
        "cottonseeds",
        "cottontails",
        "cottonweeds",
        "cottonwoods",
        "cotylosaurs",
        "coulometers",
        "coulometric",
        "councillors",
        "counselings",
        "counselling",
        "counsellors",
        "countenance",
        "counteracts",
        "counterbade",
        "counterbids",
        "counterblow",
        "countercoup",
        "counterfeit",
        "counterfire"
      ]

      stream = list |> Stream.dedup()
      exclude = MapSet.new(["a", "p"])

      tally = Counter.new() |> Counter.add_words(stream, exclude)

      assert [
               {"b", 3},
               {"c", 24},
               {"d", 6},
               {"e", 18},
               {"f", 3},
               {"g", 2},
               {"h", 1},
               {"i", 8},
               {"l", 9},
               {"m", 3},
               {"n", 21},
               {"o", 24},
               {"r", 16},
               {"s", 16},
               {"t", 20},
               {"u", 17},
               {"w", 3},
               {"y", 1}
             ] = tally |> Counter.items()
    end

    test "add words list stream with empty exclusion" do
      list = [
        "cotoneaster",
        "cotransduce",
        "cotransfers",
        "cotransport",
        "cottonmouth",
        "cottonseeds",
        "cottontails",
        "cottonweeds",
        "cottonwoods",
        "cotylosaurs",
        "coulometers",
        "coulometric",
        "councillors",
        "counselings",
        "counselling",
        "counsellors",
        "countenance",
        "counteracts",
        "counterbade",
        "counterbids",
        "counterblow",
        "countercoup",
        "counterfeit",
        "counterfire"
      ]

      stream = list |> Stream.dedup()
      exclude = MapSet.new()

      tally = Counter.new() |> Counter.add_words(stream, exclude)

      assert [
               {"a", 9},
               {"b", 3},
               {"c", 24},
               {"d", 6},
               {"e", 18},
               {"f", 3},
               {"g", 2},
               {"h", 1},
               {"i", 8},
               {"l", 9},
               {"m", 3},
               {"n", 21},
               {"o", 24},
               {"p", 2},
               {"r", 16},
               {"s", 16},
               {"t", 20},
               {"u", 17},
               {"w", 3},
               {"y", 1}
             ] = tally |> Counter.items()
    end
  end

  describe "counter merge" do
    test "merge two non-empty counters" do
      token1 = "mississippi"
      token2 = "louisiana"

      a = token1 |> Counter.new()
      b = token2 |> Counter.new()

      assert [{"i", 4}, {"m", 1}, {"p", 2}, {"s", 4}] = a |> Counter.items()

      assert [{"a", 2}, {"i", 2}, {"l", 1}, {"n", 1}, {"o", 1}, {"s", 1}, {"u", 1}] =
               b |> Counter.items()

      c = Counter.merge(a, b)

      assert [
               {"a", 2},
               {"i", 6},
               {"l", 1},
               {"m", 1},
               {"n", 1},
               {"o", 1},
               {"p", 2},
               {"s", 5},
               {"u", 1}
             ] == c |> Counter.items()
    end

    test "merge two counters, 1 empty" do
      a = Counter.new("mississippi")
      b = Counter.new("")

      c = Counter.merge(a, b)

      # The merged counter should be the same as the original non-empty counter
      assert a |> Counter.items() == c |> Counter.items()
    end

    test "merge two empty counters" do
      a = Counter.new("")
      b = Counter.new("")

      c = Counter.merge(a, b)

      # The merged counter should be the same as the original non-empty counter
      assert a |> Counter.items() == c |> Counter.items()
      assert b |> Counter.items() == c |> Counter.items()
    end
  end

  describe "counter delete" do
    test "delete no letters" do
      pattern = "A-OCA-O"
      tally = Counter.new(pattern)

      tally2 = tally |> Counter.delete([""])

      assert true = Counter.equal?(tally, tally2)

      tally2 = tally |> Counter.delete(["Z"])

      assert true = Counter.equal?(tally, tally2)
    end

    test "delete single letter" do
      pattern = "A-OCA-O"
      tally = Counter.new(pattern)

      tally = tally |> Counter.delete(["A"])

      assert [{"-", 2}, {"C", 1}, {"O", 2}] = tally |> Counter.items()

      # delete is idempotent

      tally = tally |> Counter.delete(["A"])

      assert [{"-", 2}, {"C", 1}, {"O", 2}] = tally |> Counter.items()
    end

    test "delete multiple letters" do
      pattern = "A-OCA-O"
      tally = Counter.new(pattern)

      tally = tally |> Counter.delete(["A", "Z", "-"])

      assert [{"C", 1}, {"O", 2}] = tally |> Counter.items()
    end

    test "delete entire counter" do
      pattern = "A-OCA-O"
      tally = Counter.new(pattern)

      assert true = Counter.empty?(Counter.delete(tally))
    end

    test "delete entire counter with counters complete list" do
      pattern = "A-OCA-O"
      tally = Counter.new(pattern)
      empty = Counter.delete(tally, tally |> Counter.keys())

      assert true = Counter.equal?(Counter.new(), empty)
    end
  end

  describe "general CRUD behavior" do
    test "crud mixed together simple" do
      mystery_letter = "-"
      pattern = "A-OCA-O"

      tally = Counter.new(pattern)

      assert !Counter.empty?(tally)
      assert [{"-", 2}, {"A", 2}, {"C", 1}, {"O", 2}] = Counter.items(tally)

      IO.puts("Counter: #{inspect(tally)}")

      tally = Counter.delete(tally, [mystery_letter])

      assert [{"A", 2}, {"C", 1}, {"O", 2}] = tally |> Counter.items()

      tally = Counter.add_letters(tally, "EVOKE")

      assert [{"O", 3}, {"A", 2}, {"E", 2}] = Counter.most_common(tally, 3)
      assert ["O", "A", "E"] = Counter.most_common_key(tally, 3)

      assert true = Counter.equal?(Counter.new(), Counter.delete(tally))
    end

    test "crud mixed together detailed" do
      mystery_letter = "-"
      pattern = "A-OCA-O"

      tally = Counter.new(pattern)

      assert !Counter.empty?(tally)

      tally =
        tally
        |> Counter.delete([mystery_letter])
        |> Counter.add_unique_letters("EVOKE")

      assert [{"O", 3}, {"A", 2}, {"C", 1}] = Counter.most_common(tally, 3)

      assert ["O", "A", "C"] = Counter.most_common_key(tally, 3)

      tally = tally |> Counter.inc_by("E") |> Counter.inc_by("E", 4)

      assert [{"E", 6}, {"O", 3}, {"A", 2}] = Counter.most_common(tally, 3)

      map = %{
        "i" => 43,
        "o" => 42,
        "u" => 40,
        "l" => 35,
        "c" => 29,
        "n" => 27,
        "r" => 24,
        "s" => 20,
        "m" => 17,
        "b" => 15,
        "p" => 13,
        "d" => 12,
        "h" => 9,
        "g" => 9,
        "v" => 6,
        "f" => 6,
        "j" => 3,
        "y" => 2,
        "k" => 2,
        "x" => 1,
        "z" => 1,
        "w" => 1
      }

      tally = tally |> Counter.merge(map |> Counter.new())

      assert [{"i", 43}, {"o", 42}, {"u", 40}] = Counter.most_common(tally, 3)

      tally =
        tally |> Counter.delete(["i", "o", "u"])
        |> Counter.add_unique_letters("mississippi")

      assert [{"l", 35}, {"c", 29}, {"n", 27}, {"r", 24}, {"s", 21}] =
               Counter.most_common(tally, 5)

      list = [
        "cotoneaster",
        "cotransduce",
        "cotransfers",
        "cotransport",
        "cottonmouth",
        "cottonseeds",
        "cottontails",
        "cottonweeds",
        "cottonwoods",
        "cotylosaurs",
        "coulometers",
        "coulometric",
        "councillors",
        "counselings",
        "counselling",
        "counsellors",
        "countenance",
        "counteracts",
        "counterbade",
        "counterbids",
        "counterblow",
        "countercoup",
        "counterfeit",
        "counterfire"
      ]

      tally = Counter.add_words(tally, list)

      assert [
               {"A", 2},
               {"C", 1},
               {"E", 6},
               {"K", 1},
               {"O", 3},
               {"V", 1},
               {"a", 9},
               {"b", 18},
               {"c", 53},
               {"d", 18},
               {"e", 18},
               {"f", 9},
               {"g", 11},
               {"h", 10},
               {"i", 9},
               {"j", 3},
               {"k", 2},
               {"l", 44},
               {"m", 21},
               {"n", 48},
               {"o", 24},
               {"p", 16},
               {"r", 40},
               {"s", 37},
               {"t", 20},
               {"u", 17},
               {"v", 6},
               {"w", 4},
               {"x", 1},
               {"y", 3},
               {"z", 1}
             ] = tally |> Counter.items()

      empty = Counter.delete(tally, tally |> Counter.keys())

      assert true = Counter.equal?(Counter.new(), empty)
    end
  end
end
