defmodule Hangman.Dictionary.Cache.Server do
	use GenServer

  require Logger

  alias Hangman.Dictionary.File, as: DictFile
	alias Hangman.{Counter, Word.Chunks}

	@ets_table_name :dictionary_cache_table

	# Used to insert the word list chunks and frequency counter tallies, 
	# indexed by word length 2..28, for both the normal and big 
  # dictionary file sizes
	@possible_length_keys MapSet.new(2..28)


  # Use for admin of random words extract 
  @ets_random_words_key :random_hangman_words
  @random_words_per_chunk 10
  @min_random_word_length 5
  @max_random_word_length 15
  @max_random_words_request 10

  @name __MODULE__
	# External API

  def start_link() do
    Logger.info "Starting Hangman Dictionary Cache Server"
    args = {}
    options = [name: :hangman_dictionary_cache_server]
    GenServer.start_link(@name, args, options)
  end


  def lookup(:random, count) do
    pid = Process.whereis(:hangman_dictionary_cache_server)  
    true = is_pid(pid) 
    
    lookup(pid, :random, count)
  end



  def lookup(:tally, length_key)
  when is_number(length_key) and length_key > 0 do
    pid = Process.whereis(:hangman_dictionary_cache_server)  
    true = is_pid(pid) 
  
    lookup(pid, :tally, length_key)
  end

  def lookup(:chunks, length_key)
  when is_number(length_key) and length_key > 0 do
    pid = Process.whereis(:hangman_dictionary_cache_server)
    true = is_pid(pid)

    lookup(pid, :chunks, length_key)
  end


  def lookup(pid, :random, count) do
    GenServer.call pid, {:lookup_random, count}
  end

  def lookup(pid, :tally, length_key)
  when is_number(length_key) and length_key > 0 do
    GenServer.call pid, {:lookup_tally, length_key}
  end

  def lookup(pid, :chunks, length_key)
  when is_number(length_key) and length_key > 0 do
    GenServer.call pid, {:lookup_chunks, length_key}
  end

	def stop(pid) do
		GenServer.call pid, :stop
	end

  def init({}) do
    setup()
    {:ok, {}}
  end

  def handle_call({:lookup_random, count}, _from, {}) do
    data = do_lookup(:random, count)
    {:reply, data, {}}
  end

  def handle_call({:lookup_tally, length_key}, _from, {}) do
    data = do_lookup(:tally, length_key)
    {:reply, data, {}}
  end

  def handle_call({:lookup_chunks, length_key}, _from, {}) do
    data = do_lookup(:chunks, length_key)
    {:reply, data, {}}
  end
 
	def handle_call(:stop, _from, {}) do
		{ :stop, :normal, :ok, {}}
	end 

	def terminate(_reason, _state) do
		:ok
	end

  # Dictionary Cache Abstraction Methods

	# CREATE (and UPDATE)

	# Setup cache ets
	defp setup() do
		case :ets.info(@ets_table_name) do
			:undefined ->
        # transform dictionary file, 3 times if necessary
        path = DictFile.transform(:normal, :sorted)
        |> DictFile.transform(:sorted, :grouped)
        |> DictFile.transform(:grouped, :chunked)

				load(@ets_table_name, path)

			_ -> raise "cache already setup!"
		end
	end


	# READ


	defp do_lookup(:random, count) when is_number(count) do

    if count > @max_random_words_request do
      raise "requested random words exceeds limit"
    end

		if :ets.info(@ets_table_name) == :undefined do
      raise "table not loaded yet"
    end

    ets_key = @ets_random_words_key
			
		fn_reduce_random_words = fn
			{^ets_key, ets_value}, acc ->

        List.flatten(ets_value, acc)
			_, acc -> acc	
		end

		randoms = :ets.foldl(fn_reduce_random_words, [], @ets_table_name)

    # seed random number generator with random seed
    << a :: 32, b :: 32, c :: 32 >> = :crypto.rand_bytes(12)
    r_seed = {a, b, c}
    :random.seed r_seed
    :random.seed r_seed

    randoms = for _x <- 1..count do Enum.random(randoms) end
    randoms = Enum.shuffle(randoms)

    randoms
	end



	# Retrieve dictionary tally counter given word secret length

	defp do_lookup(:tally, length_key) 
		when is_number(length_key) and length_key > 0 do

		if :ets.info(@ets_table_name) == :undefined do
      raise "table not loaded yet"
    end

		case MapSet.member?(@possible_length_keys, length_key) do
			true -> 
				ets_key = get_ets_counter_key(length_key)
				
				case :ets.match_object(@ets_table_name, {ets_key, :_}) do
					[] -> raise "counter not found for key: #{inspect length_key}"
					[{_key, ets_value}] -> 
						counter = :erlang.binary_to_term(ets_value)
						counter
				end

			false -> raise "key not in set of possible keys!"
		end
	end

	defp do_lookup(:chunks, length_key) do

		if :ets.info(@ets_table_name) == :undefined do
      raise "table not loaded yet"
    end

		ets_key = get_ets_chunk_key(length_key)
			
		fn_reduce_chunks = fn
			{^ets_key, ets_value}, acc ->
			# we pin to specified ets {chunk, length} key
				Chunks.add(acc, ets_value) 
			_, acc -> acc	
		end

		chunks = :ets.foldl(fn_reduce_chunks, 
                        Chunks.new(length_key), @ets_table_name)

		chunks
	end

	# Load dictionary word file into ets table @ets_table_name
	# Segments of the dictionary word stream are broken up into chunks, 
	# normalized and stored in the ets
	
	# Letter frequency counters of the dictionary words 
	# arranged by length are also stored in the ets after the 
	# chunks are stored

	# Optimization Note: Converting word_list chunks to binaries
	# and counters to binaries drastically reduces ets memory footprint

	defp load(table_name, dict_path) 
	when is_atom(table_name) and is_binary(dict_path) do
    
    :ets.new(table_name, [:bag, :named_table, :protected])
    
		do_load(:chunks, {table_name, dict_path})
		do_load(:counters, table_name)
	end


	defp do_load(:chunks, {table_name, path}) do

		# For each words list chunk, insert into ets lambda

		fn_ets_insert_chunks = fn 
    {nil, 0} -> ""
    {words_chunk_list, length} -> 
			ets_key = get_ets_chunk_key(length)

      # record actual chunk size :)
			chunk_size = Kernel.length(words_chunk_list)
      
      # convert chunk into binary :)
			bin_chunk = :erlang.term_to_binary(words_chunk_list) 
			ets_value = {bin_chunk, chunk_size}
			:ets.insert(table_name, {ets_key, ets_value}) 
		end

		# Group the word stream by chunks, 
    # normalize the chunks then insert into ets
		
    DictFile.Stream.new(:read_chunks, path)
    |> DictFile.Stream.chunks_stream
    |> Stream.each(fn_ets_insert_chunks)
    |> Stream.each(&ets_insert_random_words/1)
		|> Stream.run

    info = :ets.info(@ets_table_name)
		Logger.debug ":chunks, ets info is: #{inspect info}\n"		
	end


	# Generate the counters from the ets and store back into the ets

	defp do_load(:counters, table_name) do

		# lambda to insert verified counter structure into ets
		fn_ets_insert_counters = fn 
			{0, nil} -> ""
		 	{length, %Counter{} = counter} ->  
		 		ets_key = get_ets_counter_key(length)
		 		ets_value = :erlang.term_to_binary(counter)
		 		:ets.insert(table_name, {ets_key, ets_value})
		end

		# Given all the keys we inserted, create the tallys 
    # and insert it into the ets

		# Example key is {:chunk, 8}
		# Example {length, counter} is: {8,
		#		 %Counter{entries: %{"a" => 14490, "b" => 4485, "c" => 7815,
		#		 "d" => 8046, "e" => 19600, "f" => 2897, "g" => 6009, "h" => 5111,
		#		 "i" => 15530, "j" => 384, "k" => 2628, "l" => 11026, "m" => 5793,
		#		 "n" => 12186, "o" => 11462, "p" => 5763, "q" => 422, "r" => 14211,
		#		 "s" => 16560, "t" => 11870, "u" => 7377, "v" => 2156, "w" => 2313,
		#		 "x" => 662, "y" => 3395, "z" => 783}}}

		get_ets_keys_lazy(table_name) 
		|> Stream.map(&generate_tally(table_name, &1)) 
	  |> Stream.each(fn_ets_insert_counters)
		|> Stream.run

    info = :ets.info(@ets_table_name)
		Logger.debug ":counter + chunks, ets info is: #{inspect info}\n"		
	end

	# Simple helpers to generate tuple keys for ets based on word length size

	defp get_ets_chunk_key(length_key) do
		true = MapSet.member?(@possible_length_keys, length_key)
		_ets_key = {:chunk, length_key}
	end

	defp get_ets_counter_key(length_key) do
		true = MapSet.member?(@possible_length_keys, length_key)
		_ets_key = {:counter, length_key}
	end


	# Tally letter frequencies from all words of similiar length
	# as specified by length_key
	# We are only generating tallys from chunks of words, 
  # not existing tallies or randoms

	defp generate_tally(table_name, ets_key = {:chunk, length}) do
		# Use for pattern matching when we do ets.foldl

    # acc is the counter here
		fn_reduce_key_chunks_into_counter = fn
    # we pin to function arg's specified key
		{^ets_key, {bin_chunk, _size} = _value}, acc -> 
			  # convert back from binary to words list chunk
			  word_list = :erlang.binary_to_term(bin_chunk)
        Counter.add_words(acc, word_list)
			
      _, acc -> acc	
		end

		counter = :ets.foldl(fn_reduce_key_chunks_into_counter, 
			Counter.new(), table_name)
    
		{length, counter}
	end

	# Lazily gets inserted ets keys, by traversing the ets table keys
	# This is wrapped into a Stream using Stream.resource/3

  # Ensure we are only gettin gkeys which match chunk keys!

	defp get_ets_keys_lazy(table_name) when is_atom(table_name) do
		eot = :"$end_of_table"

		Stream.resource(
			fn -> [] end,

			fn acc ->
				case acc do
					[] -> 
						case :ets.first(table_name) do
							^eot -> {:halt, acc}
              first_key = {:chunk, _} -> {[first_key], first_key}
							first_key -> {[], first_key}
						end

					acc -> 
						case :ets.next(table_name, acc) do	
							^eot -> {:halt, acc}
							next_key = {:chunk, _} ->	{[next_key], next_key}
              next_key -> {[], next_key}
						end
				end
			end,

			fn _acc -> :ok end
		)
	end

#  defp ets_insert_random_words({nil, 0}), do: ""

  defp ets_insert_random_words({words_chunk_list, length}) do
    cond do

      length >= @min_random_word_length and length <= @max_random_word_length ->
        # seed random number generator with random seed
        << a :: 32, b :: 32, c :: 32 >> = :crypto.rand_bytes(12)
        r_seed = {a, b, c}
        :random.seed r_seed
        :random.seed r_seed
      
        # Grab @random_words_per_chunk random words
      
        rand = for _x <- 1..@random_words_per_chunk do 
          Enum.random(words_chunk_list) 
        end
      
        # Remove duplicate random words
        random_words = rand |> Enum.sort |> Enum.dedup

        :ets.insert(@ets_table_name, {@ets_random_words_key, random_words})

        #Logger.debug "hangman random words, length_key #{length}: #{inspect random_words}"

      true -> ""
    end
  end

end

