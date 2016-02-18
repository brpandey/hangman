defmodule Hangman.Dictionary.Cache.Timing.Profile do
  import ExProf.Macro

  alias Hangman.{Dictionary, Word.Chunks, Counter}


  def go_simple do
    profile do
      run_setup_test
    end
  end 

  def go_hard do
    :fprof.apply(&run_test/0, [])
    :fprof.profile()
    :fprof.analyse()
  end 

  def run_setup_test do
    {:ok, _pid} = Dictionary.Cache.Server.start_link()
  end
  
  def run_test do

    {:ok, pid} = Dictionary.Cache.Server.start_link()

		IO.puts "finished cache setup"

		size = 8

		lookup = Dictionary.Cache.Server.lookup(pid, :tally, size)

		counter_8 = Counter.new(%{"a" => 14490, "b" => 4485, 
			"c" => 7815, "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, 
			"h" => 5111, "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, 
			"m" => 5793, "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, 
			"r" => 14211, "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, 
			"w" => 2313, "x" => 662, "y" => 3395, "z" => 783})

    ^counter_8 = lookup

		IO.puts "#{inspect lookup}"

		chunks = %Chunks{} = Dictionary.Cache.Server.lookup(pid, :chunks, 8)

		word_count = 28558

		^word_count = Chunks.get_count(chunks, :words)

		IO.puts "chunks: #{inspect chunks}"

		Chunks.get_words_lazy(chunks)
		|> Stream.each(&IO.inspect/1)
		|> Enum.take(20)
  end
end
