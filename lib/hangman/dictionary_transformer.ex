defmodule Hangman.Dictionary.Transformer do

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

defmodule Hangman.Dictionary.CompositeTransformer do

  alias Hangman.{Dictionary}

  @moduledoc """
  The original `Dictionary` file is transformed into 
  intermediary representations. Given an original dictionary file f1, this 
  file may be transformed a few times until it is suitable to be loaded 
  into `ETS`.  E.g. `f1` -> `f2` -> `f3` -> `f4`.

  This sequence of transforms is done initially and does
  not need to be repeated unless the original file changes.

  Dictionary word load time is only determined by the last transformed file `f4`, 
  which is optimized for `ETS` load.
  """

  def run(kind) when is_atom(kind) do
    Dictionary.Sorter.run(kind)
    Dictionary.Grouper.run(kind)
    Dictionary.Chunker.run(kind)
  end

end


defmodule Hangman.Dictionary.Sorter do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.{Transformer}
  alias Hangman.Dictionary.File.{Writer}

  @behaviour Transformer

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


defmodule Hangman.Dictionary.Grouper do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.{Transformer}
  alias Hangman.Dictionary.File.{Writer}

  @behaviour Transformer
  
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


defmodule Hangman.Dictionary.Chunker do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.{Transformer}
  alias Hangman.Dictionary.File.{Writer}

  @behaviour Transformer

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
