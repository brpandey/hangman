defmodule Hangman.Words.Stream do
	defmodule State do
		defstruct file: Nil, type: Nil, group_id: -1, group_index: -1
	end

	def new(type = :sorted_dictionary_stream, path) do
		file = File.open!(path) 
		%State{ file: file, type: type}
	end

	def new(type = :lines_only_stream, path) do
		file = File.open!(path) 
		%State{ file: file, type: type}
	end

	def words(%State{} = state), do: do_words(state, state.type)


	defp do_words(%State{} = state, :sorted_dictionary_stream) do
		Stream.resource(
			fn ->	state	end,
		
			fn state ->
				case IO.read(state.file, :line) do
					"\n" -> {[], state}

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

	defp do_words(%State{} = state, :lines_only_stream) do
		Stream.resource(
			fn -> state end,
		
			fn state ->
				case IO.read(state.file, :line) do
					"" -> {[], state}

					data when is_binary(data) ->
						data = data |> String.downcase 
						{ [data], state }

					_ -> {:halt, state}
				end
			end,
			
			fn state -> File.close(state.file) end)
	end

end