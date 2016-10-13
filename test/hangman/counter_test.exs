
defmodule Hangman.Counter.Test do
  use ExUnit.Case, async: true

  alias Hangman.Counter, as: Counter

  setup_all do
    IO.puts "Counter Test"
    :ok
  end


  # Basic CRUD Functionality: Create, Read, Update, Delete
  
  test "basic counter crud" do

    mystery_letter = "-"
    hangman_pattern = "A-OCA-O"

    tally = Counter.new(hangman_pattern)

    assert !Counter.empty?(tally)

    IO.puts "Counter: #{inspect tally}"

    tally = Counter.delete(tally, [mystery_letter])

    IO.puts "Counter: #{inspect tally}"

    tally = Counter.add_letters(tally, "EVOKE")

    IO.puts "Counter: #{inspect tally}"

    assert [{"O",3}, {"A",2}, {"E",2}] = Counter.most_common(tally, 3)

    assert ["O", "A", "E"] = Counter.most_common_key(tally, 3)

    tuple_list = [{"O",3}, {"A",2}, {"E",2}]

    tally = Counter.new(tuple_list)

    tally = Counter.inc_by(tally, "E", 5)

    assert [{"E", 7}, {"O", 3}, {"A", 2}] = Counter.most_common(tally, 10)

    IO.puts "Counter: #{inspect tally}"

    map = %{"i" => 43, "o" => 42, "u" => 40, "l" => 35, "c" => 29, "n" => 27, "r" => 24, "s" => 20, "m" => 17, "b" => 15, "p" => 13, "d" => 12, "h" => 9, "g" => 9, "v" => 6, "f" => 6, "j" => 3, "y" => 2, "k" => 2, "x" => 1, "z" => 1, "w" => 1}

    tally = Counter.new(map)

    assert [{"i", 43}, {"o", 42}, {"u", 40}] = Counter.most_common(tally, 3)

    IO.puts "Counter: #{inspect tally}"

    tally = Counter.new

    # 1 "m", 1 "i", 1 "s", 1 "p"
    tally = Counter.add_unique_letters(tally, "mississippi")

    IO.puts "Counter unique: #{inspect tally}"

    tally = Counter.new

    tally = Counter.add_unique_letters(tally, "mississippi")

    assert [{"i", 1}, {"m", 1}, {"p", 1}, {"s", 1}] =
      Counter.most_common(tally, 5)

    tally = Counter.new

    tally = Counter.add_letters(tally, "mississippi")

    assert [{"i", 4}, {"s", 4}, {"p", 2}, {"m", 1}] = 
      Counter.most_common(tally, 5)

    word_list = ["cotoneaster","cotransduce","cotransfers","cotransport","cottonmouth","cottonseeds","cottontails","cottonweeds","cottonwoods","cotylosaurs","coulometers","coulometric","councillors","counselings","counselling","counsellors","countenance","counteracts","counterbade","counterbids","counterblow","countercoup","counterfeit","counterfire"]

    tally = Counter.new

    tally = Counter.add_words(tally, word_list)

    IO.puts "Counter word list: #{inspect tally}"

    IO.puts "Counter: deleted -- #{inspect Counter.delete(tally)}"
  end


  test "merge operation, two non-empty counters" do

    a = Counter.new("mississippi")
    
    assert [{"i", 4}, {"m", 1}, {"p", 2}, {"s", 4}] = a |> Counter.items

    b = Counter.new("louisiana")  

    assert [{"a", 2}, {"i", 2}, {"l", 1}, {"n", 1}, {"o", 1}, {"s", 1}, {"u", 1}] = 
      b |> Counter.items

    c = Counter.merge(a, b)

    assert [{"a", 2}, {"i", 6}, {"l", 1}, {"m", 1}, {"n", 1}, {"o", 1}, {"p", 2},
            {"s", 5}, {"u", 1}] == c |> Counter.items

  end


  test "merge operation, two counters, 1 empty" do
    
    a = Counter.new("mississippi")

    b = Counter.new("")

    c = Counter.merge(a, b)

    # The merged counter should be the same as the original non-empty counter
    assert a |> Counter.items == c |> Counter.items

  end


end
