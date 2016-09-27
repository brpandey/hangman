defmodule Hangman.Dictionary.File.Transformer do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.File.{Writer}

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

  # Run the transform

  @spec run(Dictionary.kind, fun(), {Dictionary.transform, Dictionary.transform}) :: String.t
  def run(kind, fn_transform, {src, dest}) when is_atom(kind) do

    # assert 
    true = kind in [Dictionary.regular, Dictionary.big]
    
    # Access path string from nested data structure
    path = get_in Dictionary.paths, [kind, src]
    new_path = get_in Dictionary.paths, [kind, dest]

    # create the writer given the specific transform function
    transform_handler = Writer.make_writer(fn_transform)

    # run the transform!!!
    transform_handler.(path, new_path)
  end

end



defmodule Hangman.Dictionary.File.Sorter do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.File.{Reader, Transformer}

  @behaviour Transformer

  # called from fn_transform
  def write("\n", _file_pid), do:  nil
  def write(term, file_pid) when is_pid(file_pid), do: IO.write(file_pid, term)
  
  # sort specific transform
  # do a greedy read, sort it in memory, and then write out
  def transform(read_path, file_pid) when is_pid(file_pid) do
    Reader.new(Dictionary.original, read_path)
    |> Reader.proceed
    |> Enum.sort_by(&String.length/1, &<=/2)
    |> Enum.each(&write(&1, file_pid))
  end
  
  def run(kind) when is_atom(kind) do
    Transformer.run(kind, &transform/2, {Dictionary.original, Dictionary.sorted})
  end

end


defmodule Hangman.Dictionary.File.Grouper do

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.File.{Reader, Transformer}

  @behaviour Transformer
  
  def write({length, index, word}, file_pid) when is_pid(file_pid) do
    IO.puts(file_pid, "#{length} #{index} #{word}")
  end
  
  # group specific transform

  # the reader handler for the sorted type already groups
  # the entries making output easy, just writing out the tuple
  def transform(read_path, file_pid) when is_pid(file_pid) do
    Reader.new(Dictionary.sorted, read_path)
    |> Reader.proceed
    |> Stream.each(&write(&1, file_pid))
    |> Stream.run
  end

  def run(kind) when is_atom(kind) do
    Transformer.run(kind, &transform/2, {Dictionary.sorted, Dictionary.grouped})
  end

end


defmodule Hangman.Dictionary.File.Chunker do

  alias Hangman.{Dictionary, Chunks}
  alias Hangman.Dictionary.File.{Reader, Transformer}

  @behaviour Transformer

  # convert to binary for speed and compactness
  def write(chunk, file_pid) when is_pid(file_pid) do
    bin_chunk = :erlang.term_to_binary(chunk)
    _ = IO.binwrite(file_pid, bin_chunk)
    
    # Add delimiter after every chunk, easier for chunk retrieval
    IO.binwrite(file_pid, Dictionary.chunks_file_delimiter)
  end

  # chunk specific transform
  # uses transform function to convert group stream to chunks stream
  def transform(read_path, file_pid) when is_pid(file_pid) do
    Reader.new(Dictionary.grouped, read_path) 
    |> Reader.proceed
    |> Chunks.Stream.transform(Dictionary.grouped, Dictionary.chunked)
    |> Stream.each(&write(&1, file_pid))
    |> Stream.run
  end

  def run(kind) when is_atom(kind) do
    Transformer.run(kind, &transform/2, {Dictionary.grouped, Dictionary.chunked})
  end

end
