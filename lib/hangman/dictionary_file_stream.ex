defmodule Hangman.Dictionary.File.Stream do

	alias Hangman.{Word.Chunks}

	# A chunk contains at most 2_000 words
	@chunk_words_size 2_000
  
  # Used to delimit chunk values in binary chunks file..
  @chunks_file_delimiter :erlang.term_to_binary({8,1,8,1,8,1})

	defmodule State do
		defstruct file: nil, type: nil, group_id: -1, group_index: -1
	end
  

  # Takes input file, applies a transform type and returns new file path
  # For example, can be used to first sort a file, then upon
  # second invocation, group that file

	def transform_and_write(path, new_path, type) 
	when is_binary(path) and is_binary(new_path) and 
  type in [:sort, :group, :chunk] do

		case File.open(new_path) do
			{:ok, _file} -> new_path
			{:error, :enoent} ->
				{:ok, write_file} = File.open(new_path, [:append])

				fn_write_lambda = fn 
					"\n" ->	nil
					term -> IO.write(write_file, term) 
				end

        fn_write_group_lambda = fn
          {length, index, word} -> 
            IO.puts(write_file, "#{length} #{index} #{word}")
        end

        fn_write_chunk_lambda = fn
          chunk ->
            bin_chunk = :erlang.term_to_binary(chunk)
            IO.binwrite(write_file, bin_chunk)
            # Add delimiter after every chunk, easier for chunk retrieval
            IO.binwrite(write_file, @chunks_file_delimiter)
        end

        # Process by transform type, then apply transforms
        case type do
          :sort -> 
				    new(:read_unsorted, path)
				    |> get_data_lazy
					  |> Enum.sort_by(&String.length/1, &<=/2)
					  |> Enum.each(fn_write_lambda)

          :group ->
            new(:read_sorted, path)
            |> get_data_lazy
            |> Stream.each(fn_write_group_lambda)
            |> Stream.run

          :chunk ->
            new(:read_grouped, path) 
            |> get_data_lazy
            |> Chunks.transform_stream(:sorted_grouped, @chunk_words_size)
            |> Stream.each(fn_write_chunk_lambda)
		        |> Stream.run
          
            _ -> raise "Unsupported type"
          
				  File.close(write_file)

		    end
    end

    new_path
	end


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
      data when data in [""] -> {Nil, 0}
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
