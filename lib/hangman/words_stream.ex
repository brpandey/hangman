defmodule Hangman.Words.Stream do

	def words(:dictionary, path) do
		Stream.resource(
			fn -> File.open!(path) end,
		
			fn file ->
				case IO.read(file, :line) do
					data when is_binary(data) ->

						data = data |> String.strip |> String.downcase 
						slength = String.length(data)

						{ [{slength, data}], file }


					_ -> {:halt, file}
				end
			end,
			
			fn file -> File.close(file) end)
	end

	def words(:line, path) do
		Stream.resource(
			fn -> File.open!(path) end,
		
			fn file ->
				case IO.read(file, :line) do
					data when is_binary(data) ->

						data = data |> String.downcase 

						{ [data], file }


					_ -> {:halt, file}
				end
			end,
			
			fn file -> File.close(file) end)
	end


	def words(:length, length, path) do
		Stream.resource(
			fn -> File.open!(path) end,
		
			fn file ->
				case IO.read(file, :line) do
					data when is_binary(data) ->

						data = data |> String.strip |> String.downcase 
						slength = String.length(data)

						if slength == length do
							{ [data], file }
						else
							{ [], file }
						end

					_ -> {:halt, file}
				end
			end,
			
			fn file -> File.close(file) end)
	end

end