defmodule Hangman.Dictionary.Cache do
	#use GenServer

	@dictionary_chunks 500
	@words_chunk_size 1_000

	@dictionary_normal_path "lib/hangman/data/words.txt"
	@dictionary_normal_sorted_path "lib/hangman/data/words_sorted.txt"
	@dictionary_big_path "lib/hangman/data/words_big.txt"
	@dictionary_big_sorted_path "lib/hangman/data/words_big_sorted.txt"

	@dictionary_path @dictionary_normal_path
	@dictionary_sorted_path @dictionary_normal_sorted_path
	
	#Total normal dictionary size is about @dictionary_chunks * @words_chunk_size = 200 * 1_000 = 200_000 words
	#Total big dictionary size is about @dictionary_chunks * @words_chunk_size = 400 * 1_000 = 400_000 words

	# This is for the hangman word dictionary (both normal and big)
	# Specifically not dynamically generating atoms from lengths to serve as an assert 
	# and restrict the number of atoms to this static map

	# @chunk_key_map indexed by word length,
	# returns atom key for the word chunks for that length
	@chunk_key_map %{
		2 => :chunk_key_2, 3 => :chunk_key_3, 4 => :chunk_key_4, 
		5 => :chunk_key_5, 6 => :chunk_key_6, 7 => :chunk_key_7, 
		8 => :chunk_key_8, 9 => :chunk_key_9, 10 => :chunk_key_10, 
		11 => :chunk_key_11, 12 => :chunk_key_12, 13 => :chunk_key_13, 
		14 => :chunk_key_14, 15 => :chunk_key_15, 16 => :chunk_key_16,
		17 => :chunk_key_17, 18 => :chunk_key_18, 19 => :chunk_key_19, 
		20 => :chunk_key_20, 21 => :chunk_key_21, 22 => :chunk_key_22, 
		23 => :chunk_key_23, 24 => :chunk_key_24, 25 => :chunk_key_25, 
		26 => :chunk_key_26, 27 => :chunk_key_27, 28 => :chunk_key_28
	}

	# @counter_key_map indexed by word length
	# returns atom key of the counter object for that length
	@counter_key_map %{
		2 => :counter_key_2, 3 => :counter_key_3, 4 => :counter_key_4, 
		5 => :counter_key_5, 6 => :counter_key_6, 7 => :counter_key_7, 
		8 => :counter_key_8, 9 => :counter_key_9, 10 => :counter_key_10, 
		11 => :counter_key_11, 12 => :counter_key_12, 13 => :counter_key_13, 
		14 => :counter_key_14, 15 => :counter_key_15, 16 => :counter_key_16,
		17 => :counter_key_17, 18 => :counter_key_18, 19 => :counter_key_19, 
		20 => :counter_key_20, 21 => :counter_key_21, 22 => :counter_key_22, 
		23 => :counter_key_23, 24 => :counter_key_24, 25 => :counter_key_25, 
		26 => :counter_key_26, 27 => :counter_key_27, 28 => :counter_key_28
	}

	# TODO : Split into two modules, Hangman.Dictionary.Cache and Hangman.Words.Stream

	def sort_and_write() do

		case File.open(@dictionary_sorted_path) do
			{:ok, _file} -> :ok
			{:error, :enoent} ->
				{:ok, file} = File.open(@dictionary_sorted_path, [:append])

				ws = Hangman.Words.Stream.new(:lines_only_stream, @dictionary_path)

				write_lambda = fn 
					"\n" ->	Nil
					term -> IO.write(file, term) 
				end

				Hangman.Words.Stream.words(ws)
					|> Enum.sort_by(&String.length/1, &<=/2)
					|> Enum.each(write_lambda)

				File.close(file)

				Hangman.Words.Stream.delete(ws)
		end	

	end


	# Load dictionary word file into ets table :dictionary_cache
	def load() do
		:ets.new(:dictionary_cache, [:bag, :named_table, :protected])

		ws = Hangman.Words.Stream.new(:sorted_dictionary_stream, @dictionary_sorted_path)

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
					key = Map.get(@chunk_key_map, length)
					:ets.insert(:dictionary_cache, {key, words_chunk_list}) 
		end

		Hangman.Words.Stream.words(ws)
			|> Stream.chunk_by(fn_length_bufsize_seq_chunks)  
			|> Stream.map(fn_map_chunks)
			#|> Stream.each(fn chunk -> IO.puts("New chunk!: #{inspect chunk}\n") end)
			|> Stream.each(fn_ets_insert_chunks)
			|> Enum.take(@dictionary_chunks)

		#IO.puts "ets info is: #{inspect :ets.info(:dictionary_cache)}\n"

		Hangman.Words.Stream.delete(ws)


		fn_ets_insert_counters = fn 
		 	{length, %Hangman.Counter{} = counter} ->  
		 		key = Map.get(@counter_key_map, length)
		 		:ets.insert(:dictionary_cache, {key, counter})
		 		#IO.puts "Just inserted counter: #{inspect counter} for key: #{key}"
		end

		# Given all the keys we inserted, create the tallys and insert it into the ets
		get_inserted_keys() |> Enum.map(&generate_tally(&1)) |> Enum.map(fn_ets_insert_counters)


		#IO.puts "ets info 2 is: #{inspect :ets.info(:dictionary_cache)}\n"

	end	



	# Retrieve tally counter

	def lookup_tally(secret_length) 
	when is_number(secret_length) and secret_length > 0 do

		case Map.has_key?(@counter_key_map, secret_length) do
			true -> 
				key = Map.get(@counter_key_map, secret_length)
				
				case :ets.lookup(:dictionary_cache, key) do
					[] -> raise "Counter not found for key: #{key}"
					[{_key, counter}] -> counter
				end

			false -> raise "Key not found!"
		end

	end

	# Get inserted key lengths

	defp get_inserted_keys() do
		list = Enum.reduce(Map.keys(@chunk_key_map), [], fn head, acc -> 
				case :ets.lookup(:dictionary_cache, Map.get(@chunk_key_map, head)) do
					[] -> acc
					_ -> [acc, head]
				end
			end)

		List.flatten(list)
	end

	# Tally letter frequencies from all words of similiar length
	# as specified by secret_length

	defp generate_tally(secret_length) 
	when is_number(secret_length) and secret_length > 0 do

		key = Map.get(@chunk_key_map, secret_length)
		
		fn_reduce_words_into_counter = fn 
			head, acc -> Hangman.Counter.add_unique_letters(acc, head)
		end

		fn_reduce_key_chunks_into_counter = fn
			{^key, word_list}, acc -> Enum.reduce(word_list, acc, fn_reduce_words_into_counter)
			_, acc -> acc	
		end

		counter = :ets.foldl(fn_reduce_key_chunks_into_counter, 
			Hangman.Counter.new(), :dictionary_cache)

		{secret_length, counter}
	end


end
