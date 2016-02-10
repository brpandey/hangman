defmodule Hangman.Dictionary.Stream do
	defmodule State do
		defstruct file: nil, type: nil, group_id: -1, group_index: -1
	end

	@moduledoc """
		Glorified state wrapper around two types of streams: 
			sorted dictionary files and unsorted dictionary files

		Sorted dictionary file type streams, also have length, the actual word value, 
		and the word group index by length information included as part of this stream 
	"""

	# Create

	def new(type = :sorted, path) do
		file = File.open!(path) 
		%State{ file: file, type: type}
	end

	def new(type = :unsorted, path) do
		file = File.open!(path) 
		%State{ file: file, type: type}
	end

	# Read / Update

	def get_lazy(%State{} = state), do: do_words(state, state.type)

	# Delete

	def delete(%State{} = state) do
		File.close(state.file)
		%State{}
	end	

	# Private

	defp do_words(%State{} = state, :sorted) do
		Stream.resource(
			fn ->	state	end,
		
			fn state ->
				case IO.read(state.file, :line) do
					data when data in ["\n", ""] -> {[], state}

					data when is_binary(data) ->
						data = data |> String.strip |> String.downcase 
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

						{ [{length, data, state.group_index}], state }

					_ -> {:halt, state}
				end
			end,
			
			fn state -> File.close(state.file) end)
	end

	defp do_words(%State{} = state, :unsorted) do
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
