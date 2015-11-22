defmodule Hangman.Dictionary do

	def sleep(seconds) do
		receive do
			after seconds * 1000 -> nil
		end
	end

	def say(text) do
		spawn fn -> :os.cmd('espeak #{text}') end
		spawn fn -> :os.cmd('say #{text}') end

		sleep 2
	end

	def words(length) do
		Stream.resource(
			fn -> File.open!("data/words.txt") end,
		
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
