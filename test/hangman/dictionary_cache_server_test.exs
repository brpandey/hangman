defmodule Hangman.Dictionary.Cache.Server.Test do
	use ExUnit.Case #, async: true

	alias Hangman.{Dictionary, Counter, Word.Chunks}

  setup_all do
    IO.puts "Hangman.Dictionary.Cache.Server.Test"
    :ok
  end


	test "initial test of dictionary cache" do

		pid = 
      case Dictionary.Cache.Server.start_link do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
    
		IO.puts "finished cache setup"

		size = 8

#		assert catch_error(Dictionary.Cache.Server.lookup(pid, :tally, 3383)) ==
#		  %RuntimeError{message: "key not in set of possible keys!"}

		lookup = Dictionary.Cache.Server.lookup(pid, :tally, size)

		counter_8 = Counter.new(%{"a" => 14490, "b" => 4485, 
			"c" => 7815, "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, 
			"h" => 5111, "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, 
			"m" => 5793, "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, 
			"r" => 14211, "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, 
			"w" => 2313, "x" => 662, "y" => 3395, "z" => 783})

		IO.puts "lookup is: #{inspect lookup}"

		assert Counter.equal?(lookup, counter_8)
		
		IO.puts "Counters match\n\n"
	
		chunks = %Chunks{} = Dictionary.Cache.Server.lookup(pid, :chunks, 8)

		word_count = 28558

		assert word_count == Chunks.get_count(chunks, :words)

		IO.puts "chunks: #{inspect chunks}"

    randoms = Dictionary.Cache.Server.lookup(pid, :random, 10)
    IO.puts "random hangman words 1: #{inspect randoms}"

    randoms = Dictionary.Cache.Server.lookup(pid, :random, 10)
    IO.puts "random hangman words 2: #{inspect randoms}"

    randoms = Dictionary.Cache.Server.lookup(pid, :random, 10)
    IO.puts "random hangman words 3: #{inspect randoms}"


		Chunks.get_words_lazy(chunks)
		|> Stream.each(&IO.inspect/1)
		|> Enum.take(20)


    Dictionary.Cache.Server.stop(pid)
	end


end
