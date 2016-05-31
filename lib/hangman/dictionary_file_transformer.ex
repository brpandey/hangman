defmodule Hangman.Dictionary.File.Transformer do

  @moduledoc """
  This module specifies the interface routines to transform 
  the input dictionary file to a new file, based on the 
  logic of the transform function.

  The behaviour implementing modules provide the routines to 
  generate various intermediate and cached `Dictionary` files.

  Implemented Transformation types are `original` to `sorted`, `sorted` to `grouped`, 
  and `grouped` to `chunked`.  Each transform handler encapsulates each 
  transform procedure.
  """

  # Writes new file term
  @callback write(term, pid) :: term

  # Reads input stream and transforms file 
  @callback transform(String.t, pid) :: :ok

  # Runs transform 1-arity
  @callback run(kind :: atom) :: String.t

end



defmodule Hangman.Dictionary.File.Sorter do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.File.{Reader, Writer}

  @behaviour Hangman.Dictionary.File.Transformer

  # called from fn_transform
  def write("\n", _file_pid), do:  nil
  def write(term, file_pid) when is_pid(file_pid), do: IO.write(file_pid, term)
  
  # sort specific transform
  def transform(read_path, file_pid) when is_pid(file_pid) do

    Reader.new(Dictionary.original, read_path)
    |> Reader.stream
    |> Enum.sort_by(&String.length/1, &<=/2)
    |> Enum.each(&write(&1, file_pid))
  end
  
  # run the transform
  # transform from original to sorted
  @spec run(atom) :: String.t
  def run(kind) when is_atom(kind) do

    # assert 
    true = kind in [Dictionary.regular, Dictionary.big]
    
    # Access path string from nested data structure
    path = get_in Dictionary.paths, [kind, Dictionary.original]
    new_path = get_in Dictionary.paths, [kind, Dictionary.sorted]

    transform_handler = Writer.make_writer(&transform/2)
    transform_handler.(path, new_path)
  end

end


defmodule Hangman.Dictionary.File.Grouper do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.File.{Writer, Reader}

  @behaviour Hangman.Dictionary.File.Transformer
  
  def write({length, index, word}, file_pid) when is_pid(file_pid) do
    IO.puts(file_pid, "#{length} #{index} #{word}")
  end
  
  # group specific transform
  def transform(read_path, file_pid) when is_pid(file_pid) do
    Reader.new(Dictionary.sorted, read_path)
    |> Reader.stream
    |> Stream.each(&write(&1, file_pid))
    |> Stream.run
  end


  # run the transform
  # transform from sorted to grouped
  @spec run(atom) :: String.t

  def run(kind) when is_atom(kind) do

    # assert 
    true = kind in [Dictionary.regular, Dictionary.big]
        
    # Access path string from nested data structure
    path = get_in Dictionary.paths, [kind, Dictionary.sorted]
    new_path = get_in Dictionary.paths, [kind, Dictionary.grouped]

    transform_handler = Writer.make_writer(&transform/2)
    transform_handler.(path, new_path)
  end

end


defmodule Hangman.Dictionary.File.Chunker do

  alias Hangman.{Dictionary, Chunks}
  alias Hangman.Dictionary.File.{Reader, Writer}

  @behaviour Hangman.Dictionary.File.Transformer

  def write(chunk, file_pid) when is_pid(file_pid) do
    bin_chunk = :erlang.term_to_binary(chunk)
    IO.binwrite(file_pid, bin_chunk)
    
    # Add delimiter after every chunk, easier for chunk retrieval
    IO.binwrite(file_pid, Dictionary.chunks_file_delimiter)
  end

  # chunk specific transform
  def transform(read_path, file_pid) when is_pid(file_pid) do
    Reader.new(Dictionary.grouped, read_path) 
    |> Reader.stream
    |> Chunks.Stream.transform(Dictionary.grouped, Dictionary.chunked)
    |> Stream.each(&write(&1, file_pid))
    |> Stream.run
  end


  # run the transform
  # transform from grouped to chunked
  @spec run(atom) :: String.t
  def run(kind) when is_atom(kind) do

    # assert 
    true = kind in [Dictionary.regular, Dictionary.big]
    
    # Access path string from nested data structure

    path = get_in Dictionary.paths, [kind, Dictionary.grouped]
    new_path = get_in Dictionary.paths, [kind, Dictionary.chunked]

    transform_handler = Writer.make_writer(&transform/2)
    transform_handler.(path, new_path)
  end

end
