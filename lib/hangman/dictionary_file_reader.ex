defmodule Hangman.Dictionary.File.Reader do

  @moduledoc """
  Module for accessing input file stream for 
  various original and transformed dictionary file types ranging
  from `original`, `sorted`, `grouped`, `chunked`
  """

  alias Hangman.{Dictionary}
  alias Hangman.Dictionary.File.{Reader}

  defstruct file: nil, type: nil, group_id: -1, group_index: -1

  @opaque t :: %__MODULE__{}

  @original Dictionary.original
  @sorted Dictionary.sorted
  @grouped Dictionary.grouped
  @chunked Dictionary.chunked

  @type_handler_map %{
    @original => &Dictionary.File.OriginalReader.handler/1,
    @sorted => &Dictionary.File.SortedReader.handler/1,
    @grouped => &Dictionary.File.GroupedReader.handler/1,
    @chunked => &Dictionary.File.ChunkedReader.handler/1
  }

  @doc """
  Handles file specific input `streams`, wrapping underlying file formats.
  Returns file `enumerable`, closes file when finished.
  """
  @callback handler(io_device :: IO.device) :: Enumerable.t  


  # Create
  @doc """
  Returns a new empty file reader
  """

  @spec new(Dictionary.transform, String.t) :: t
  def new(type, path) when type in 
  [@original, @sorted, @grouped, @chunked] do
    file = File.open!(path)
    %Reader{ file: file, type: type}
  end


  # Read / Update
  @doc """
  Proceed returns input file `enumerable`
  """

  @spec proceed(t) :: Enumerable.t
  def proceed(%Reader{} = reader) do
    handler = Map.get(@type_handler_map, reader.type)
    handler.(reader)
  end

  # Delete

  @doc """
  Deletes `reader`, returns empty file `stream`
  """

  @spec delete(t) :: t
  def delete(%Reader{} = reader) do
    File.close(reader.file)
    %Reader{}
  end 
end



# chunked file specific input stream, wrapping underlying file

defmodule Hangman.Dictionary.File.ChunkedReader do

  alias Hangman.Dictionary.File.{Reader}

  @behaviour Reader

  @chunks_file_delimiter Hangman.Dictionary.chunks_file_delimiter

  def handler(%Reader{} = reader) do

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

    chunks_enumerable = reader.file
    |> IO.binread(:all)
    |> :binary.split(@chunks_file_delimiter, [:global])
    |> Enum.map(fn_unpack)

    # close the file
    File.close(reader)

    chunks_enumerable
  end
end


defmodule Hangman.Dictionary.File.GroupedReader do

  alias Hangman.Dictionary.File.{Reader}

  @behaviour Reader

  # grouped file specific input stream generator, wrapping underlying file

  def handler(%Reader{} = reader) do
    Stream.resource(
      fn -> reader end,
    
      fn reader ->
        case IO.read(reader.file, :line) do
          # if newline or empty binary prompt for next value in stream
          data when data in ["\n", ""] -> {[], reader}
          
          data when is_binary(data) ->
              # split line into group attributes
              [len, ind, word] = String.split(data, " ")
              length = String.to_integer(len)
              index = String.to_integer(ind)
              word = word |> String.strip
            { [{length, index, word}], reader }

          _ -> {:halt, reader}
        end
      end,
      
      # be a responsible file user upon stream end
      fn reader -> File.close(reader.file) end)
  end
end


defmodule Hangman.Dictionary.File.SortedReader do

  alias Hangman.Dictionary.File.{Reader}

  @behaviour Reader

  # sorted file specific input stream generator, wrapping underlying file
  # since we know the input is sorted, we can create a grouping output

  def handler(%Reader{} = reader) do
    Stream.resource(
      fn -> reader end,
    
      fn reader ->
        case IO.read(reader.file, :line) do
          # if newline or empty binary prompt for next value in stream
          data when data in ["\n", ""] -> {[], reader}

          data when is_binary(data) ->
            data = data |> String.strip
            length = String.length(data)

            # Tracking group index as we iterate through the stream, to 
            # allow the logic alg to be "online" as we have access to prev value
            # with the addition of the Reader module

            reader = 
              case reader.group_id == length do
                true -> 
                  # increment the group ctr index by 1
                  Kernel.put_in(reader.group_index, reader.group_index + 1)
                false ->
                  # update new group_id and reset ctr index to 1
                  reader = Kernel.put_in(reader.group_id, length)               
                  Kernel.put_in(reader.group_index, 1)
              end
            
            { [{length, reader.group_index, data}], reader }

          _ -> {:halt, reader}
        end
      end,

      # be a responsible file user upon stream end      
      fn reader -> File.close(reader.file) end)
  end
end


defmodule Hangman.Dictionary.File.OriginalReader do

  alias Hangman.Dictionary.File.{Reader}

  @behaviour Reader

  # handles original dictionary file

  def handler(%Reader{} = reader) do
    Stream.resource(
      fn -> reader end,
    
      fn reader ->
        case IO.read(reader.file, :line) do
          # if newline or empty binary prompt for next value in stream
          data when data in ["\n", ""] -> {[], reader}
          
          data when is_binary(data) ->
              # Since we are dealing with the original dictionary file
              # make sure words are lowercased
              data = data |> String.downcase
            
            { [data], reader }

          _ -> {:halt, reader}
        end
      end,

      # be a responsible file user upon stream end      
      fn reader -> File.close(reader.file) end)
  end

end
