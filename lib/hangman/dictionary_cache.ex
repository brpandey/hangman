defmodule Hangman.Dictionary.Cache do
	#use GenServer

	# A chunk contains at most 500 words
	@chunk_words_size 500

	@ets_table_name :hangman_dictionary_cache

	# Used to insert the word list chunks and frequency counter tallies, 
	# indexed by word length 2..28, for both the normal and big dictionary file sizes
	@possible_keys MapSet.new(2..28)

	# Dictionary path file names
	@dictionary_normal_path "lib/hangman/data/words.txt"
	@dictionary_normal_sorted_path "lib/hangman/data/words_sorted.txt"
	@dictionary_big_path "lib/hangman/data/words_big.txt"
	@dictionary_big_sorted_path "lib/hangman/data/words_big_sorted.txt"

	# Active dictionary paths in use by program
	@dictionary_path @dictionary_normal_path
	@dictionary_sorted_path @dictionary_normal_sorted_path


	# PUBLIC

	# CREATE (and UPDATE)

	# Setup cache ets
	def setup() do
		case :ets.info(@ets_table_name) do
			:undefined ->
				sort_and_write(@dictionary_path, @dictionary_sorted_path)
				load(@ets_table_name, @dictionary_sorted_path, @chunk_words_size)

			_ -> raise "Cache already setup!"
		end
	end


	# READ

	# Retrieve dictionary tally counter given word secret length

	def lookup_tally(secret_length) 
		when is_number(secret_length) and secret_length > 0 do

		if :ets.info(@ets_table_name) == :undefined, do: raise "table not loaded yet"

		case MapSet.member?(@possible_keys, secret_length) do
			true -> 
				key = get_ets_counter_key(secret_length)
				
				case :ets.lookup(@ets_table_name, key) do
					[] -> raise "Counter not found for key: #{inspect key}"
					[{_key, counter}] -> counter
				end

			false -> raise "Key not in set of possible keys!"
		end

	end

	# PRIVATE

	# Sort dictionary words file and write to new file.  
	# If already sorted, use sorted file.

	defp sort_and_write(path, sorted_path) 
		when is_binary(path) and is_binary(sorted_path) do

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

				Hangman.Words.Stream.delete(ws)
		end	

	end

	# Load dictionary word file into ets table @ets_table_name
	# Segments of the dictionary are broken up into chunks, 
	# normalized and stored in the ets
	
	# Letter frequency counters of the dictionary words 
	# arranged by length are also stored in the ets after the 
	# chunks are stored

	defp load(table_name, sorted_path, buffer_size) 
		when is_atom(table_name) and is_binary(sorted_path) 
		and is_number(buffer_size) and buffer_size > 0 do

		do_load(table_name, sorted_path, buffer_size, :chunks)
		do_load(table_name, :counters)
	end


	defp do_load(table_name, sorted_path, buffer_size, :chunks) do
		:ets.new(table_name, [:bag, :named_table, :protected])

		ws = Hangman.Words.Stream.new(:sorted_dictionary_stream, sorted_path)

		# lambda to split stream into chunks based on generated chunk id
		# Uses 1 + div() function to group consecutive, sorted words
		# Takes into account the current word-length-group index position and 
		# specified words-chunk buffer size, to determine chunk id

		#	A) Example of word stream before chunking
		#	{6, "mugful", 8509}
		#	{6, "muggar", 8510}
		#	{6, "mugged", 8511}
		#	{6, "muggee", 8512}

		fn_split_into_chunks = fn 
			{length, _word, length_group_index} -> 
				_chunk_id = length * ( 1 + div(length_group_index, buffer_size))
		end

		# lambda to normalize chunks
		# Flatten out / normalize chunks so that they contain only a list of words, 
		# and word length size

		# B) Example of chunk, before normalization
		#	[{6, "mugful", 8509}, {6, "muggar", 8510}, {6, "mugged", 8511},
		#	 {6, "muggee", ...}, {6, ...}, {...}, ...]

		fn_normalize_chunks = fn 
			chunk -> 
				Enum.map_reduce(chunk, "", 
					fn {length, word, _}, _acc -> {word, length} end)
		end

		#	C) Example of chunk after normalization
		#	{["mugful", "muggar", "mugged", "muggee", ...], 6}

		# For each words list chunk, insert into ets lambda

		fn_ets_insert_chunks = fn 
			{words_chunk_list, length} -> 
					key = get_ets_chunk_key(length)
					:ets.insert(table_name, {key, words_chunk_list}) 
		end

		# Group the word stream by chunks, normalize the chunks then insert into ets
		Hangman.Words.Stream.words(ws)
			|> Stream.chunk_by(fn_split_into_chunks)  
			|> Stream.map(fn_normalize_chunks)
			|> Stream.each(fn_ets_insert_chunks)
			|> Stream.run

		Hangman.Words.Stream.delete(ws)

		IO.puts ":chunks, ets info is: #{inspect :ets.info(@ets_table_name)}\n"		
	end

	defp do_load(table_name, :counters) do

		# lambda to insert verified counter structure into ets
		fn_ets_insert_counters = fn 
			{0, Nil} -> ""
		 	{length, %Hangman.Counter{} = counter} ->  
		 		key = get_ets_counter_key(length)
		 		:ets.insert(table_name, {key, counter})
		end

		# Given all the keys we inserted, create the tallys and insert it into the ets

		# Example key is {:chunk, 8}
		# Example {length, counter} is: {8,
		#		 %Hangman.Counter{entries: %{"a" => 14490, "b" => 4485, "c" => 7815,
		#		    "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, "h" => 5111,
		#		    "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, "m" => 5793,
		#		    "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, "r" => 14211,
		#		    "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, "w" => 2313,
		#		    "x" => 662, "y" => 3395, "z" => 783}}}

		get_ets_keys_lazy(table_name) 
		|> Stream.map(&generate_tally(table_name, &1)) 
		|> Stream.each(fn_ets_insert_counters)
		|> Stream.run

		IO.puts ":counter + chunks, ets info is: #{inspect :ets.info(@ets_table_name)}\n"		
	end

	# Simple helpers to generate tuple keys for ets based on word length size

	defp get_ets_chunk_key(word_length) do
		true = MapSet.member?(@possible_keys, word_length)
		{:chunk, word_length}
	end

	defp get_ets_counter_key(word_length) do
		true = MapSet.member?(@possible_keys, word_length)
		{:counter, word_length}
	end	


	# Tally letter frequencies from all words of similiar length
	# as specified by secret_length

	# We are only generating tallys from chunks of words, not existing tallies
	defp generate_tally(_name, {:counter, _length}), do: {0, Nil}

	defp generate_tally(table_name, key = {:chunk, length}) 
		when is_number(length) and length > 0 do
		
		fn_reduce_words_into_counter = fn 
			head, acc -> Hangman.Counter.add_unique_letters(acc, head)
		end

		fn_reduce_key_chunks_into_counter = fn
			{^key, word_list}, acc -> Enum.reduce(word_list, acc, fn_reduce_words_into_counter)
			_, acc -> acc	
		end

		counter = :ets.foldl(fn_reduce_key_chunks_into_counter, 
			Hangman.Counter.new(), table_name)

		{length, counter}
	end

	# Lazily gets inserted ets keys, by traversing the ets table keys
	# This is wrapped into a Stream using Stream.resource/3

	defp get_ets_keys_lazy(table_name) when is_atom(table_name) do
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

