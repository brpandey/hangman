defmodule Hangman.Dictionary.File.Stream do
  @moduledoc """
  Module for accessing input file stream for 
  various original and transformed dictionary file types ranging
  from `unsorted`, `sorted`, `grouped`, `chunked`
  """

  alias Hangman.Dictionary.File.Stream, as: FileStream

  alias Hangman.{Dictionary}

  defstruct file: nil, type: nil, group_id: -1, group_index: -1

  @opaque t :: %__MODULE__{}

  @type mode :: :read

  # Dictionary attribute tokens
  @unsorted Dictionary.unsorted
  @sorted Dictionary.sorted
  @grouped Dictionary.grouped
  @chunked Dictionary.chunked

  @chunks_file_delimiter Dictionary.chunks_file_delimiter


  # Create
  @doc """
  Returns a new empty file `stream`
  """

  @spec new({mode, Dictionary.transform}, String.t) :: t
  def new(type = {:read, dict_file_type}, path)
  when dict_file_type in [@sorted, @unsorted, @grouped, @chunked] do
    file = File.open!(path)
    %FileStream{ file: file, type: type}
  end


  # Read / Update
  @doc """
  Returns input file `stream`
  """

  @spec gets_lazy(t) :: Enumerable.t
  def gets_lazy(%FileStream{} = fstream) do
    file_handler(fstream, fstream.type)
  end

  # Delete

  @doc """
  Deletes `fstream`, returns empty file `stream`
  """

  @spec delete(t) :: t
  def delete(%FileStream{} = fstream) do
    File.close(fstream.file)
    %FileStream{}
  end 


  # Private

  # chunked file specific input stream, wrapping underlying file

  @doc """
  Handles file specific input `streams`, wrapping underlying file formats.
  Returns file `stream`, closes file when finished.  Normally accessed
  through `gets_lazy/1`.
  """
  @spec file_handler(t, {mode, Dictionary.transform}) :: Enumerable.t

  def file_handler(%FileStream{} = fstream, {:read, @chunked}) do

    # Given the chunks file, read it in raw binary mode all it once
    # split it based on the delimiter
    # unpack each chunk with the binary_to_term method
    # serve when ready..

    fn_unpack = fn
      data when data in [""] -> 
        {nil, 0}
      bin when is_binary(bin) -> 
        :erlang.binary_to_term(bin)
    end

    chunks_stream = fstream.file
    |> IO.binread(:all)
    |> :binary.split(@chunks_file_delimiter, [:global])
    |> Stream.map(fn_unpack)
    
    chunks_stream
  end
  
  # grouped file specific input stream generator, wrapping underlying file

  def file_handler(%FileStream{} = fstream, {:read, @grouped}) do
    Stream.resource(
      fn -> fstream end,
    
      fn fstream ->
        case IO.read(fstream.file, :line) do
          # if newline or empty binary prompt for next value in stream
          data when data in ["\n", ""] -> {[], fstream}
          
          data when is_binary(data) ->
              # split line into group attributes
              [len, ind, word] = String.split(data, " ")
              length = String.to_integer(len)
              index = String.to_integer(ind)
              word = word |> String.strip
            { [{length, index, word}], fstream }

          _ -> {:halt, fstream}
        end
      end,
      
      # be a responsible file user upon stream end
      fn fstream -> File.close(fstream.file) end)
  end

  # sorted file specific input stream generator, wrapping underlying file
  # since we know the input is sorted, we can create a grouping output

  def file_handler(%FileStream{} = fstream, {:read, @sorted}) do
    Stream.resource(
      fn -> fstream end,
    
      fn fstream ->
        case IO.read(fstream.file, :line) do
          # if newline or empty binary prompt for next value in stream
          data when data in ["\n", ""] -> {[], fstream}

          data when is_binary(data) ->
            data = data |> String.strip
            length = String.length(data)

            # Tracking group index as we iterate through the stream, to 
            # allow the logic alg to be "online" as we have access to prev value
            # with the addition of the Fstream module

            case fstream.group_id == length do
              true -> 
                # increment the group ctr index by 1
                fstream = Kernel.put_in(fstream.group_index, 
                                        fstream.group_index + 1)

              false ->
                # update new group_id and reset ctr index to 1
                fstream = Kernel.put_in(fstream.group_id, length)               
                fstream = Kernel.put_in(fstream.group_index, 1)
            end

            { [{length, fstream.group_index, data}], fstream }

          _ -> {:halt, fstream}
        end
      end,

      # be a responsible file user upon stream end      
      fn fstream -> File.close(fstream.file) end)
  end

  # unsorted file specific input stream generator, wrapping underlying file
  # likely handles original dictionary file

  def file_handler(%FileStream{} = fstream, {:read, @unsorted}) do
    Stream.resource(
      fn -> fstream end,
    
      fn fstream ->
        case IO.read(fstream.file, :line) do
          # if newline or empty binary prompt for next value in stream
          data when data in ["\n", ""] -> {[], fstream}
          
          data when is_binary(data) ->
              # Since we are dealing with the original dictionary file
              # make sure words are lowercased
              data = data |> String.downcase
            
            { [data], fstream }

          _ -> {:halt, fstream}
        end
      end,

      # be a responsible file user upon stream end      
      fn fstream -> File.close(fstream.file) end)
  end

end
