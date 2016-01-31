
defmodule Hangman.Words.Stream.Test do
	use ExUnit.Case, async: true


	test "test printing 5 unsorted dictionary words of variable lengths" do

		IO.puts "lines of unsorted dictionary"
		
		path = "lib/hangman/data/words.txt"

		ws = Hangman.Words.Stream.new(:lines_only_stream, path)

		Hangman.Words.Stream.words(ws)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)
	end


	test "test lines only printing 5 dictionary words of variable lengths" do

		IO.puts "sorted dictionary"

		path = "lib/hangman/data/words_sorted.txt"

		ws = Hangman.Words.Stream.new(:sorted_dictionary_stream, path)

		Hangman.Words.Stream.words(ws)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)
	end


end