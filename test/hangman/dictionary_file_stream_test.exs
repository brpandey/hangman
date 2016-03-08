defmodule Dictionary.File.Stream.Test do
	use ExUnit.Case, async: true

  setup_all do
    IO.puts "Dictionary File Stream Test"
    :ok
  end


	test "test lines only type stream, print first 5 lines" do

		IO.puts "lines of unsorted dictionary"
		
		path = "lib/hangman/data/words.txt"

		stream = Dictionary.File.Stream.new({:read, :unsorted}, path)

		Dictionary.File.Stream.gets_lazy(stream)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)

		Dictionary.File.Stream.delete(stream)			
	end


	test "test sorted dictionary type stream, print first 5 sorted words" do

		IO.puts "sorted dictionary"

		path = "lib/hangman/data/words_sorted.txt"

		sorted_stream = Dictionary.File.Stream.new({:read, :sorted}, path)

		Dictionary.File.Stream.gets_lazy(sorted_stream)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)

		Dictionary.File.Stream.delete(sorted_stream)	
	end


end
