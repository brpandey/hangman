
defmodule Hangman.Counter.Test do
	use ExUnit.Case, async: true

	alias Hangman.Counter, as: Counter

	# Basic CRUD Functionality: Create, Read, Update, Delete
	
	test "test string constructor" do

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

		tuple_list = [{"O",3}, {"A",2}, {"E",2}]

		tally = Counter.new(tuple_list)

		tally = Counter.inc(tally, "E", 5)

		assert [{"E", 7}, {"O", 3}, {"A", 2}] = Counter.most_common(tally, 3)

		IO.puts "Counter: #{inspect tally}"


	end

end