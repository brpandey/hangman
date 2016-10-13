defmodule Hangman.Dictionary.Cache.Timing.Profile do
  import ExProf.Macro

  @moduledoc false

  alias Hangman.{Dictionary, Counter, Chunks}

  # Module to time dictionary cache server

  @doc """
  Profiling routine that conducts a simple test
  """

  @spec go_simple :: term
  def go_simple do
    profile do
      run_setup_test
    end
  end 

  @doc """
  Profiling routine that conducts an elaborate, long test
  """

  @spec go_hard :: term
  def go_hard do
    :fprof.apply(&run_test/0, [])
    :fprof.profile()
    :fprof.analyse()
  end 

  defp run_setup_test do
    Dictionary.stop

    {:ok, _pid} = Dictionary.Cache.start_link([type: :regular, ingestion: true])
  end
  
  defp run_test do
    Dictionary.stop

    {:ok, pid} = Dictionary.Cache.start_link([type: :regular, ingestion: true])

    IO.puts "finished cache setup"

    size = 8

    lookup = Dictionary.Cache.lookup(pid, :tally, size)

    counter_8 = Counter.new(%{"a" => 14490, "b" => 4485, 
      "c" => 7815, "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, 
      "h" => 5111, "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, 
      "m" => 5793, "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, 
      "r" => 14211, "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, 
      "w" => 2313, "x" => 662, "y" => 3395, "z" => 783})

    ^counter_8 = lookup

    IO.puts "#{inspect lookup}"

    chunks = %Chunks{} = Dictionary.Cache.lookup(pid, :chunks, 8)

    word_count = 28558

    ^word_count = Chunks.count(chunks)

    IO.puts "chunks: #{inspect chunks}"

    Chunks.get_words_lazy(chunks)
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(20)
  end
end
