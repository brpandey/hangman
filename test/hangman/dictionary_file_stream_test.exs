
defmodule Hangman.Dictionary.File.Stream.Test do
	use ExUnit.Case, async: true

  setup_all do
    IO.puts "Hangman.Dictionary.File.Stream.Test"
    :ok
  end


	test "test lines only type stream, print first 5 lines" do

		IO.puts "lines of unsorted dictionary"
		
		path = "lib/hangman/data/words.txt"

		stream = Hangman.Dictionary.File.Stream.new({:read, :unsorted}, path)

		Hangman.Dictionary.File.Stream.gets_lazy(stream)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)

		Hangman.Dictionary.File.Stream.delete(stream)			
	end


	test "test sorted dictionary type stream, print first 5 sorted words" do

		IO.puts "sorted dictionary"

		path = "lib/hangman/data/words_sorted.txt"

		sorted_stream = Hangman.Dictionary.File.Stream.new({:read, :sorted}, path)

		Hangman.Dictionary.File.Stream.gets_lazy(sorted_stream)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)

		Hangman.Dictionary.File.Stream.delete(sorted_stream)	
	end


end
