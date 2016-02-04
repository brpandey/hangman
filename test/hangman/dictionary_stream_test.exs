
defmodule Hangman.Dictionary.Stream.Test do
	use ExUnit.Case, async: true


	test "test lines only type stream, print first 5 lines" do

		IO.puts "lines of unsorted dictionary"
		
		path = "lib/hangman/data/words.txt"

		stream = Hangman.Dictionary.Stream.new(:unsorted, path)

		Hangman.Dictionary.Stream.get_lazy(stream)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)

		Hangman.Dictionary.Stream.delete(stream)			
	end


	test "test sorted dictionary type stream, print first 5 sorted words" do

		IO.puts "sorted dictionary"

		path = "lib/hangman/data/words_sorted.txt"

		sorted_stream = Hangman.Dictionary.Stream.new(:sorted, path)

		Hangman.Dictionary.Stream.get_lazy(sorted_stream)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)

		Hangman.Dictionary.Stream.delete(sorted_stream)	
	end


end