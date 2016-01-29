defmodule Hangman.Dictionary.Cache do
	#use GenServer

	@dictionary_size 500_000
	# This is only for the hangman word dictionary, TODO dynamically generate atoms from lengths
	@length_atom_keys_map %{2 => :key_2, 3 => :key_3, 4 => :key_4, 5 => :key_5, 6 => :key_6,
											7 => :key_7, 8 => :key_8, 9 => :key_9, 10 => :key_10, 11 => :key_11,
											12 => :key_12, 13 => :key_13, 14 => :key_14, 15 => :key_15, 16 => :key_16,
											17 => :key_17, 18 => :key_18, 19 => :key_19, 20 => :key_20, 21 => :key_21,
											22 => :key_22, 23 => :key_23, 24 => :key_24, 25 => :key_25, 26 => :key_26,
											27 => :key_27, 28 => :key_28}

	# TODO : Split into two modules, Hangman.Dictionary.Cache and Hangman.Words.Stream

	def sort_and_write() do
		path = "lib/hangman/data/words.txt"
		sorted_path = "lib/hangman/data/words_sorted.txt"

		case File.open(sorted_path) do
			{:ok, _file} -> :ok
			{:error, :enoent} ->
				{:ok, file} = File.open(sorted_path, [:append])
				
				Hangman.Words.Stream.words(:line, path)
					|> Enum.sort_by(&String.length/1, &<=/2)
					|> Enum.each(&IO.write(file, &1))

				:ok
		end	

	end

	# Load dictionary word file into ets table :dictionary_cache
	def load() do
		:ets.new(:dictionary_cache, [:bag, :named_table, :protected])

		path = "lib/hangman/data/words_sorted.txt"

		Hangman.Words.Stream.words(:dictionary, path)
			|> Stream.each(fn {length, word} -> 
					key = Map.get(@length_atom_keys_map, length)
					:ets.insert(:dictionary_cache, {key, word}) end)
			#|> Stream.each(&IO.inspect/1)
			|> Enum.take(@dictionary_size)


		IO.puts "ets info is: #{inspect :ets.info(:dictionary_cache)}"

	end

	# Tally letter frequencies from all words of similiar length
	# as specified by secret_length
	def tally(secret_length) 
	when is_number(secret_length) and secret_length > 0 do

		key = Map.get(@length_atom_keys_map, secret_length)

		lambda = fn 
			{^key, value}, acc -> Hangman.Counter.add_unique_letters(acc, value) 
			_, acc -> acc	
		end

		counter = :ets.foldl(lambda, Hangman.Counter.new(), :dictionary_cache)

		counter
	end
end
