
defmodule Hangman.Counter.Test do
	use ExUnit.Case, async: true

	alias Hangman.Counter, as: Counter

	# Basic CRUD Functionality: Create, Read, Update, Delete
	
	test "test basic counter crud" do

		mystery_letter = "-"
		hangman_pattern = "A-OCA-O"

		tally = Counter.new(hangman_pattern)

		assert !Counter.empty?(tally)

		IO.puts "Counter: #{inspect tally}"

		tally = Counter.delete(tally, [mystery_letter])

		IO.puts "Counter: #{inspect tally}"

		tally = Counter.add(tally, "EVOKE")

		IO.puts "Counter: #{inspect tally}"

		assert [{"O",3}, {"A",2}, {"E",2}] = Counter.most_common(tally, 3)

		assert ["O", "A", "E"] = Counter.most_common_key(tally, 3)

		tuple_list = [{"O",3}, {"A",2}, {"E",2}]

		tally = Counter.new(tuple_list)

		tally = Counter.inc(tally, "E", 5)

		assert [{"E", 7}, {"O", 3}, {"A", 2}] = Counter.most_common(tally, 10)

		IO.puts "Counter: #{inspect tally}"

		map = %{"i" => 43, "o" => 42, "u" => 40, "l" => 35, "c" => 29, "n" => 27, "r" => 24, "s" => 20, "m" => 17, "b" => 15, "p" => 13, "d" => 12, "h" => 9, "g" => 9, "v" => 6, "f" => 6, "j" => 3, "y" => 2, "k" => 2, "x" => 1, "z" => 1, "w" => 1}

		tally = Counter.new(map)

		assert [{"i", 43}, {"o", 42}, {"u", 40}] = Counter.most_common(tally, 3)

		IO.puts "Counter: #{inspect tally}"

		IO.puts "Counter: deleted -- #{inspect Counter.delete(tally)}"
	end
end