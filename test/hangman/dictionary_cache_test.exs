defmodule Hangman.Dictionary.Cache.Test do
	use ExUnit.Case, async: true

	test "initial test of cache" do

		Hangman.Dictionary.Cache.sort_and_write()

		IO.puts "sort and write finished"
		
		Hangman.Dictionary.Cache.load()

		IO.puts "finished loading"

		size = 8

		ctr = Hangman.Dictionary.Cache.lookup_tally(size)

		IO.puts "Counter of length #{size} is: #{inspect ctr}"
		IO.puts "\n\n"
	end
end