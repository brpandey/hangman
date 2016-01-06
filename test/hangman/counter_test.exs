
defmodule Hangman.Counter.Test do
	use ExUnit.Case, async: true

	alias Hangman.Counter, as: Counter

	# Basic CRUD Functionality: Create, Read, Update, Delete
	
	test "test string constructor" do

		mystery_letter = "-"
		hangman_pattern = "A-OCA-O"

		tally = Counter.new(hangman_pattern)

		IO.puts "Counter: #{inspect tally}"

		tally = Counter.delete(tally, [mystery_letter])

		IO.puts "Counter: #{inspect tally}"

		tally = Counter.add(tally, "EVOKE")

		IO.puts "Counter: #{inspect tally}"

		assert ["O", "A", "E"] = Counter.most_common(tally, 3)

	end

end