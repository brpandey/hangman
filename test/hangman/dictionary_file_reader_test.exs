defmodule Hangman.Dictionary.File.Reader.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Dictionary, Dictionary.File.Reader}

  setup_all do
    IO.puts "Dictionary Reader Test"
    :ok
  end


  test "test lines only type stream, print first 5 lines" do

    IO.puts "lines of unsorted dictionary"


    root_path =  :code.priv_dir(:play)
    read_path = "#{root_path}/dictionary/data/words.txt"

    reader = Reader.new(Dictionary.original, read_path)

    reader
    |> Reader.stream
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(5)

    Reader.delete(reader)     
  end


  test "test sorted dictionary type stream, print first 5 sorted words" do

    IO.puts "sorted dictionary"

    root_path =  :code.priv_dir(:play)
    read_path = "#{root_path}/dictionary/data/words_sorted.txt"

    reader = Reader.new(Dictionary.sorted, read_path)

    reader
    |> Reader.stream
    |> Stream.each(&IO.inspect/1)
    |> Enum.take(5)

    Reader.delete(reader)   
  end


end
