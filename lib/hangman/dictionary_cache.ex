defmodule Hangman.Dictionary.Cache do
	#use GenServer

	@dictionary_chunks 400
	@words_chunk_size 1000

	#Total dictionary size is about @dictionary_chunks * @words_chunk_size = 200 * 1000 = 200_000

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

				ws = Hangman.Words.Stream.new(:lines_only_stream, path)

				write_lambda = fn 
					"\n" ->	Nil
					term -> IO.write(file, term) 
				end

				Hangman.Words.Stream.words(ws)
					|> Enum.sort_by(&String.length/1, &<=/2)
					|> Enum.each(write_lambda)

				File.close(file)
		end	

	end

	# Load dictionary word file into ets table :dictionary_cache
	def load1() do
		:ets.new(:dictionary_cache, [:bag, :named_table, :protected])

		path = "lib/hangman/data/words_sorted.txt"

		ws = Hangman.Words.Stream.new(:sorted_dictionary_stream, path)

		Hangman.Words.Stream.words(ws)
			|> Stream.each(fn {length, word, _group_index} -> 
					key = Map.get(@length_atom_keys_map, length)
					:ets.insert(:dictionary_cache, {key, word}) end)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(@dictionary_chunks)


		IO.puts "ets info is: #{inspect :ets.info(:dictionary_cache)}"

	end

	# Load dictionary word file into ets table :dictionary_cache
	def load2() do
		:ets.new(:dictionary_cache, [:bag, :named_table, :protected])

		path = "lib/hangman/data/words_sorted.txt"

		ws = Hangman.Words.Stream.new(:sorted_dictionary_stream, path)

		fn_length_bufsize_seq_chunks = fn 
			{length, _word, length_group_index} -> 
				chunk_id = length * ( 1 + div(length_group_index, @words_chunk_size))
				#IO.puts "word, length, index, chunk_id: #{word},#{length},#{length_group_index},#{chunk_id}"
				chunk_id
		end

		fn_map_reduce_single_chunk = fn 
			{length, word, _}, _acc -> {word, length} 
		end

		fn_map_chunks = fn 
			chunk -> Enum.map_reduce(chunk, "", fn_map_reduce_single_chunk)
		end

		fn_ets_insert_chunks = fn 
			{words_chunk_list, length} -> 
					key = Map.get(@length_atom_keys_map, length)
					:ets.insert(:dictionary_cache, {key, words_chunk_list}) 
		end

		Hangman.Words.Stream.words(ws)
			|> Stream.chunk_by(fn_length_bufsize_seq_chunks)  
			|> Stream.map(fn_map_chunks)
			#|> Stream.each(fn chunk -> IO.puts("New chunk!: #{inspect chunk}\n") end)
			|> Stream.each(fn_ets_insert_chunks)
			|> Enum.take(@dictionary_chunks)

		#IO.puts "final collection is: #{inspect val}\n"

		IO.puts "ets info is: #{inspect :ets.info(:dictionary_cache)}\n"

		lookup = :ets.lookup(:dictionary_cache, :key_3)

		IO.puts "ets lookup: #{inspect lookup}\n"

	end	

	# Tally letter frequencies from all words of similiar length
	# as specified by secret_length
	def tally(secret_length) 
	when is_number(secret_length) and secret_length > 0 do

		key = Map.get(@length_atom_keys_map, secret_length)

		fn_reduce_words_into_counter = fn 
			head, acc -> Hangman.Counter.add_unique_letters(acc, head)
		end

		fn_reduce_key_chunks_into_counter = fn
			{^key, word_list}, acc -> Enum.reduce(word_list, acc, fn_reduce_words_into_counter)
			_, acc -> acc	
		end

		counter = :ets.foldl(fn_reduce_key_chunks_into_counter, 
			Hangman.Counter.new(), :dictionary_cache)

		counter
	end
end
