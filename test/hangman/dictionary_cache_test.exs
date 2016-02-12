defmodule Hangman.Dictionary.Cache.Test do
	use ExUnit.Case #, async: true

	alias Hangman.{Dictionary, Counter, Word.Chunks}

	test "initial test of dictionary cache" do
    
		assert catch_error(Dictionary.Cache.lookup(:tally, 8)) ==
      %RuntimeError{message: "table not loaded yet"}

		Dictionary.Cache.setup()

 		assert catch_error(Dictionary.Cache.setup()) ==
 			%RuntimeError{message: "cache already setup!"}

		IO.puts "finished cache setup"

		size = 8

		assert catch_error(Dictionary.Cache.lookup(:tally, 383838383838383)) ==
		  %RuntimeError{message: "key not in set of possible keys!"}

		lookup = Dictionary.Cache.lookup(:tally, size)

		counter_8 = Counter.new(%{"a" => 14490, "b" => 4485, 
			"c" => 7815, "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, 
			"h" => 5111, "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, 
			"m" => 5793, "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, 
			"r" => 14211, "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, 
			"w" => 2313, "x" => 662, "y" => 3395, "z" => 783})

		IO.puts "lookup is: #{inspect lookup}"

		assert Counter.equal?(lookup, counter_8)
		
		IO.puts "Counters match\n\n"
	
		chunks = %Chunks{} = Dictionary.Cache.lookup(:chunks, 8)

		word_count = 28558

		assert word_count == Chunks.get_count(chunks, :words)

		IO.puts "chunks: #{inspect chunks}"


		Chunks.get_words_lazy(chunks)
		|> Stream.each(&IO.inspect/1)
		|> Enum.take(20)

	end


end
