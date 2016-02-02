defmodule Hangman.Dictionary.Cache do
	#use GenServer

	@ets_table_name :dictionary_cache

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


	# Used to insert the word list chunks and frequency counter tallies, 
	# indexed by word length 2..28, for both the normal and big dictionary file sizes
	@possible_keys MapSet.new(2..28)

	def get_ets_chunk_key(word_length) do
		true = MapSet.member?(@possible_keys, word_length)
		{:chunk, word_length}
	end

	def get_ets_counter_key(word_length) do
		true = MapSet.member?(@possible_keys, word_length)
		{:counter, word_length}
	end	

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


	# Load dictionary word file into ets table @ets_table_name
	# Segments of the dictionary are broken up into chunks 
	# and stored in the ets
	
	# Letter frequency counters of the dictionary words 
	# arranged by length are also stored in the ets
	def load() do
		:ets.new(@ets_table_name, [:bag, :named_table, :protected])

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
					key = get_ets_chunk_key(length)
					:ets.insert(@ets_table_name, {key, words_chunk_list}) 
		end

		Hangman.Words.Stream.words(ws)
			|> Stream.chunk_by(fn_length_bufsize_seq_chunks)  
			|> Stream.map(fn_map_chunks)
			#|> Stream.each(fn chunk -> IO.puts("New chunk!: #{inspect chunk}\n") end)
			|> Stream.each(fn_ets_insert_chunks)
			|> Enum.take(@dictionary_chunks)

		IO.puts "ets info is: #{inspect :ets.info(@ets_table_name)}\n"

		Hangman.Words.Stream.delete(ws)


		fn_ets_insert_counters = fn 
		 	{length, %Hangman.Counter{} = counter} ->  
		 		key = get_ets_counter_key(length)
		 		:ets.insert(@ets_table_name, {key, counter})
		 		IO.puts "Just inserted counter: #{inspect counter} for key: #{inspect key}"
		end

		key_sort_lambda = fn ({_, x}), ({_, y})  -> x <= y end

		# Given all the keys we inserted, create the tallys and insert it into the ets
		get_inserted_ets_keys(@ets_table_name) 
		|> Enum.sort(key_sort_lambda)
		|> Enum.map(&generate_tally(@ets_table_name, &1)) 
		|> Enum.map(fn_ets_insert_counters)

		IO.puts "ets info 2 is: #{inspect :ets.info(@ets_table_name)}\n"

	end	


	# Retrieve tally counter

	def lookup_tally(secret_length) 
	when is_number(secret_length) and secret_length > 0 do

		case MapSet.member?(@possible_keys, secret_length) do
			true -> 
				key = get_ets_counter_key(secret_length)
				
				case :ets.lookup(@ets_table_name, key) do
					[] -> raise "Counter not found for key: #{inspect key}"
					[{_key, counter}] -> counter
				end

			false -> raise "Key not found!"
		end

	end


	# Tally letter frequencies from all words of similiar length
	# as specified by secret_length

	defp generate_tally(table_name, key) 
	when is_tuple(key) and tuple_size(key) == 2 do
		
		fn_reduce_words_into_counter = fn 
			head, acc -> Hangman.Counter.add_unique_letters(acc, head)
		end

		fn_reduce_key_chunks_into_counter = fn
			{^key, word_list}, acc -> Enum.reduce(word_list, acc, fn_reduce_words_into_counter)
			_, acc -> acc	
		end

		counter = :ets.foldl(fn_reduce_key_chunks_into_counter, 
			Hangman.Counter.new(), table_name)

		{_, length} = key

		{length, counter}
	end

	# Get inserted key lengths

	defp get_inserted_ets_keys(table_name) when is_atom(table_name) do
		eot = :"$end_of_table"

		Stream.resource(
			fn -> [] end,

			fn acc ->
				case acc do
					[] -> 
						case :ets.first(table_name) do
							^eot -> {:halt, acc}
							first_key -> {[first_key], first_key}						
						end

					acc -> 
						case :ets.next(table_name, acc) do	
							^eot -> {:halt, acc}
							next_key ->	{[next_key], next_key}
						end
				end
			end,

			fn _acc -> :ok end
		)
	end
end

