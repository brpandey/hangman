defmodule Dictionary.File.Stream do
  @moduledoc """
  Module for accessing input file stream for 
  various dictionary file types
  """

  alias Dictionary.File.Stream, as: FileStream

	defstruct file: nil, type: nil, group_id: -1, group_index: -1

  @type t :: %__MODULE__{}


  # Dictionary attribute tokens
  @unsorted Dictionary.unsorted
  @sorted Dictionary.sorted
  @grouped Dictionary.grouped
  @chunked Dictionary.chunked

  @chunks_file_delimiter Dictionary.chunks_file_delimiter


	# Create
  @doc """
  Returns a new empty file stream
  """

  @spec new({:atom, :atom}, String.t) :: t
  def new(type = {:read, dict_file_type}, path)
  when dict_file_type in [@sorted, @unsorted, @grouped, @chunked] do
    file = File.open!(path)
    %FileStream{ file: file, type: type}
  end


	# Read / Update
  @doc """
  Returns input file stream
  """

  @spec gets_lazy(t) :: Enumerable.t
  def gets_lazy(%FileStream{} = state), do: file_handler(state, state.type)

	# Delete

  @doc """
  Deletes state, returns empty file stream
  """

  @spec delete(t) :: t
	def delete(%FileStream{} = state) do
		File.close(state.file)
		%FileStream{}
	end	


	# Private

  # chunked file specific input stream, wrapping underlying file

  @spec file_handler(t, {:atom, :atom}) :: Enumerable.t
  defp file_handler(%FileStream{} = state, {:read, @chunked}) do

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

    chunks_stream = state.file
    |> IO.binread(:all)
    |> :binary.split(@chunks_file_delimiter, [:global])
    |> Stream.map(fn_unpack)
    
    chunks_stream
  end
  
  # grouped file specific input stream generator, wrapping underlying file

  @spec file_handler(t, {:atom, :atom}) :: Enumerable.t
	defp file_handler(%FileStream{} = state, {:read, @grouped}) do
		Stream.resource(
			fn -> state end,
		
			fn state ->
				case IO.read(state.file, :line) do
          # if newline or empty binary prompt for next value in stream
					data when data in ["\n", ""] -> {[], state}
					
					data when is_binary(data) ->
              # split line into group attributes
              [len, ind, word] = String.split(data, " ")
              length = String.to_integer(len)
              index = String.to_integer(ind)
						  word = word |> String.strip
						{ [{length, index, word}], state }

					_ -> {:halt, state}
				end
			end,
			
      # be a responsible file user upon stream end
			fn state -> File.close(state.file) end)
	end

  # sorted file specific input stream generator, wrapping underlying file
  # since we know the input is sorted, we can create a grouping output

  @spec file_handler(t, {:atom, :atom}) :: Enumerable.t
	defp file_handler(%FileStream{} = state, {:read, @sorted}) do
		Stream.resource(
			fn ->	state	end,
		
			fn state ->
				case IO.read(state.file, :line) do
          # if newline or empty binary prompt for next value in stream
					data when data in ["\n", ""] -> {[], state}

					data when is_binary(data) ->
						data = data |> String.strip
						length = String.length(data)

						# Tracking group index as we iterate through the stream, to 
						# allow the logic alg to be "online" as we have access to prev value
						# with the addition of the State module

						case state.group_id == length do
							true -> 
								# increment the group ctr index by 1
								state = Kernel.put_in(state.group_index, state.group_index + 1)

							false ->
								# update new group_id and reset ctr index to 1
								state = Kernel.put_in(state.group_id, length)								
								state = Kernel.put_in(state.group_index, 1)
						end

						{ [{length, state.group_index, data}], state }

					_ -> {:halt, state}
				end
			end,

      # be a responsible file user upon stream end			
			fn state -> File.close(state.file) end)
	end

  # unsorted file specific input stream generator, wrapping underlying file
  # likely handles original dictionary file

  @spec file_handler(t, {:atom, :atom}) :: Enumerable.t
	defp file_handler(%FileStream{} = state, {:read, @unsorted}) do
		Stream.resource(
			fn -> state end,
		
			fn state ->
				case IO.read(state.file, :line) do
          # if newline or empty binary prompt for next value in stream
					data when data in ["\n", ""] -> {[], state}
					
					data when is_binary(data) ->
              # Since we are dealing with the original dictionary file
              # make sure words are lowercased
						  data = data |> String.downcase
            
						{ [data], state }

					_ -> {:halt, state}
				end
			end,

      # be a responsible file user upon stream end			
			fn state -> File.close(state.file) end)
	end

end
