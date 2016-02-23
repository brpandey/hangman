defmodule Hangman.Dictionary.File.Stream do
  
	defmodule State do
		defstruct file: nil, type: nil, group_id: -1, group_index: -1
	end

  # Used to delimit chunk values in binary chunks file..
  @chunks_file_delimiter :erlang.term_to_binary({8,1,8,1,8,1})


	# Create

	def new(type = :read_sorted, path), do: do_new(type, path)
	def new(type = :read_unsorted, path), do: do_new(type, path)
  def new(type = :read_grouped, path), do: do_new(type, path)
  def new(type = :read_chunks, path), do: do_new(type, path)

  defp do_new(type, path) do
    file = File.open!(path)
    %State{ file: file, type: type}
  end

	# Read / Update
	def chunks_stream(%State{} = state) do

    # Assert we are in correct type
    :read_chunks = state.type

    # Given the chunks file, read it in raw binary mode all it once
    # split it based on the delimiter
    # unpack each chunk with the binary_to_term method
    # serve when ready..

    fn_unpack = fn
      data when data in [""] -> {nil, 0}
      bin when is_binary(bin) -> :erlang.binary_to_term(bin)
    end

    chunks_stream = state.file
    |> IO.binread(:all)
    |> :binary.split(@chunks_file_delimiter, [:global])
    |> Stream.map(fn_unpack)

    chunks_stream
	end


	# Delete

	def delete(%State{} = state) do
		File.close(state.file)
		%State{}
	end	


	def get_data_lazy(%State{} = state), do: read_data(state, state.type)

	# Private

	defp read_data(%State{} = state, :read_grouped) do
		Stream.resource(
			fn -> state end,
		
			fn state ->
				case IO.read(state.file, :line) do
					data when data in ["\n", ""] -> {[], state}
					
					data when is_binary(data) ->
              [len, ind, word] = String.split(data, " ")
              length = String.to_integer(len)
              index = String.to_integer(ind)
						  word = word |> String.strip
						{ [{length, index, word}], state }

					_ -> {:halt, state}
				end
			end,
			
			fn state -> File.close(state.file) end)
	end

	defp read_data(%State{} = state, :read_sorted) do
		Stream.resource(
			fn ->	state	end,
		
			fn state ->
				case IO.read(state.file, :line) do
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
			
			fn state -> File.close(state.file) end)
	end

	defp read_data(%State{} = state, :read_unsorted) do
		Stream.resource(
			fn -> state end,
		
			fn state ->
				case IO.read(state.file, :line) do
					data when data in ["\n", ""] -> {[], state}
					
					data when is_binary(data) ->
						data = data |> String.downcase
            
						{ [data], state }

					_ -> {:halt, state}
				end
			end,
			
			fn state -> File.close(state.file) end)
	end

end
