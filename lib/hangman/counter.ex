defmodule Hangman.Counter do
	defstruct entries: Map.new

	# Letter Frequency Counter for words
	
	# CREATE

	# Returns new empty Counters
	def new, do: %Hangman.Counter{}
	def new([]), do: %Hangman.Counter{}

	# Returns new Counter that reflects contents of string
	def new(word) when is_binary(word) do 
		add_letters(new(), word) 
	end
	
	# Returns new Counter	that reflects contents of tuple list
	def new(tuple_list) when is_list(tuple_list) and is_tuple(hd(tuple_list)) do
		entries = Enum.into tuple_list, Map.new
		%Hangman.Counter{ entries: entries }
	end

	# Returns new Counter	that reflects contents of Map
	def new(%{} = map) do
		entries = Enum.into map, Map.new
		%Hangman.Counter{ entries: entries }
	end

	# READ

	# Returns true if counters equal
	def equal?(%Hangman.Counter{} = c1, %Hangman.Counter{} = c2) do
			
		str1 = "#{inspect c1}"
		str2 = "#{inspect c2}"

		str1 == str2
	end

	# Returns a key-value tuple list of {letter, count} tuples
	def items(%Hangman.Counter{entries: entries} = _counter) do
		Enum.into entries, []
	end

	# Quick check to see if Counter is empty
	def empty?(%Hangman.Counter{entries: entries} = _counter) do
		Enum.empty?(entries)
	end

	# Returns list of the most common n codepoints and codepoint values
	def most_common(%Hangman.Counter{entries: entries} = _counter, n) 
		when is_number(n) and n > 0 do
		
		tuple_list = Enum.into entries, []

		#Sort from highest count to lowest count
		tuple_sort_lambda = fn ({_letter_1, x}), ({_letter_2, y})  -> y <= x end

		tuple_list 
			|> Enum.sort(tuple_sort_lambda) 
			|> Enum.take(n)
	end

	# Returns list of the most common n codepoint keys
	def most_common_key(%Hangman.Counter{} = counter, n) 
		when is_number(n) and n > 0 do
		
		most_common(counter, n)
			|> Enum.map( fn ({letter, _count }) -> letter end)	# Just grab the letter key
	end

	# UPDATE

	# Increment value for a given key by the given value - default is 1, 
	# if not there add key and value
	def inc_by(%Hangman.Counter{entries: entries} = counter, key, value \\ 1)
  when is_binary(key) and is_number(value) and value > 0 do
		%Hangman.Counter{ counter | entries: Map.update(entries, key, value, &(&1 + value)) }
	end

	# Returns an updated Counter

	# Handle case where list is empty
	def add_letters(%Hangman.Counter{} = counter, []), do: counter

  def add_letters(%Hangman.Counter{} = counter, word) when is_binary(word) do
    add_letters(counter, String.codepoints(word))
  end

	def add_letters(%Hangman.Counter{entries: entries} = counter, codepoints) do

		false = Enum.empty?(codepoints)

		# Splits word into codepoints enumerable, 
    # and then reduces this enumerable into
		# the entries dict, updating the count by one if the key
		# is already present in the entries Map, else setting 1 as the initial value

		entries_updated = 
			Enum.reduce(
				codepoints,
				entries, 
				fn head, acc -> Map.update(acc, head, 1, &(&1 + 1)) end
			)

		%Hangman.Counter{ counter | entries: entries_updated }
	end

_ = """
 if a word is "restlessness", rather than scoring it with 1 s
 collapse the duplicate s's that are consecutive to make 3 s's

    fn_filter_hangman_codepoints = fn
      head, {last_codepoint, codepoints} ->
      if head != last_codepoint do
        acc ++ head
      else
        acc
      end
      last_codepoint = head
      {last_codepoint, map}
    end
"""

	def add_unique_letters(%Hangman.Counter{} = counter, word) 
	when is_binary(word) do
		
		# Splits word into unique codepoints list, 
    # and then reduces this list into
		# the entries dict, updating the count by one if the key
		# is already present in the entries Map

		add_letters(counter, String.codepoints(word) |> Enum.uniq)
	end

	def add_unique_letters(%Hangman.Counter{} = counter, word, 
                         %MapSet{} = exclusion_set)
  when is_binary(word) do
		
		# Splits word into unique codepoints list, 
    # and then reduces this list into
		# the entries dict, updating the count by one if the key
		# is already present in the entries Map

		letter_set = MapSet.new(String.codepoints(word))

		unique_excluded = MapSet.difference(letter_set, exclusion_set)

		add_letters(counter, MapSet.to_list(unique_excluded))
	end

  def add_word_list(%Hangman.Counter{} = counter, words)
  when is_list(words) do

    fn_reduce_word_into_counter = fn
      "", acc -> acc                                    
      word, acc ->
        # seq = String.codepoints(word) |> Enum.uniq
        
        # using char lists is faster 
        seq = word |> String.to_char_list |> Enum.uniq
        
        List.flatten(seq, acc)

    end
    
    # reduce the words into a codepoints sequence
    seq_list = Enum.reduce(words, [], fn_reduce_word_into_counter)

#    IO.puts "sequence list: #{seq_list}"
#    IO.puts "sequent list, chunk_by: #{inspect seq_list |> Enum.sort |> Enum.chunk_by(&(&1)) |> Enum.map(&Enum.with_index(&1,1)) |> Enum.map(&List.last/1)}"

    grouped_codepoint_counts = seq_list 
    # e.g. the seq is ["a", "b", "d", "h", "d", "b", "b", "h", "a"] 
    |> Enum.sort
    # O(nlogn)
    # e.g. the seq is now ["a", "a", "b", "b", "b", "d", "d", "h", "h"]
    |> Enum.chunk_by(&(&1))
    # O(n)
    # e.g. the seq is now [["a", "a"], ["b", "b", "b"], ["d", "d"], ["h", "h"]]
    |> Enum.map(&Enum.with_index(&1,1))
    # O(n)
    # e.g. [[{"a", 1}, {"a", 2}], [{"b", 1}, {"b", 2}, {"b", 3}], 
    # [{"d", 1}, {"d", 2}], [{"h", 1}, {"h", 2}]]
    |> Enum.map(&List.last/1)
    # O(n)
    # e.g. final seq is: [{"a", 2}, {"b", 3}, {"d", 2}, {"h", 2}] 

    # allow for batch updating of codepoints vs updating the counter map for every codepoint
    counter = Enum.reduce(grouped_codepoint_counts, counter, fn {codepoint_value, value}, acc -> 
      inc_by(acc, :binary.list_to_bin([codepoint_value]), value)
      # inc_by(acc, codepoint_value, value)
    end)

    counter

  end

  def add_word_list(%Hangman.Counter{} = counter, words, 
                    %MapSet{} = exclusion_set)
  when is_list(words) do

    # routine to check if a word is a duplicate or in exclusion set
    fn_dup_and_exclusion_check_1_pass = fn
      codepoint, dup_val -> 
        case(MapSet.member?(exclusion_set, codepoint)) do
          # regard codepoints that are in the exclusion set as fake dupes
          # by giving the value of the first element again 
          # - we handle the edge case later :)
          true -> dup_val
          _ -> codepoint
        end
    end

    fn_reduce_word_into_counter = fn
      "", acc -> acc                                    
      word, acc ->
        seq = String.codepoints(word) # add each word's codepoint
        fake_dup_val = List.first(seq)

        seq = Enum.uniq_by(seq, &fn_dup_and_exclusion_check_1_pass.(&1, fake_dup_val))
      
        # Cover edge case if the first element we used for the fake dup val
        # if that is in the exclusion set, then drop it :)
        if MapSet.member?(exclusion_set, List.first(seq)) do
          seq = Enum.drop(seq, 1)
        end

        # Update the counter's map
        add_letters(acc, seq)
    end
    
    counter = Enum.reduce(words, counter, fn_reduce_word_into_counter)

    #counter = delete(counter, letters)

    counter
  end


  def add_words_stream(%Hangman.Counter{} = counter, words_stream, 
                    %MapSet{} = exclusion_set) do

    # acc is codepoints stream, initially it is an empty list
    counter = Enum.reduce(words_stream, counter, fn word, acc ->
      # add each word's uniq codepoint

      sequence = word |> String.codepoints |> Enum.uniq

      # Update the counter with the sorted (codepoints by word) stream
      add_letters(acc, sequence)
    end
    )
    
    # Add word delimiter empty codepoint to exclusion set
    # Remove exclusion set in one go per word list (vs. per word)
    letters = cond do
      MapSet.size(exclusion_set) > 0 ->
        exclusion_set |> MapSet.to_list
      true ->
        []
    end
    
    delete(counter, letters)
  end


	# DELETE

	# Returns an updated Counter, after deleting specified keys in letters
  def delete(%Hangman.Counter{} = counter, []), do: counter

	def delete(%Hangman.Counter{entries: entries} = counter, letters) 
		when is_list(letters) and is_binary(hd(letters)) do

		entries_updated = Map.drop(entries, letters)
		%Hangman.Counter{ counter | entries: entries_updated}
	end

	def delete(%Hangman.Counter{} = _counter) do
		%Hangman.Counter{}
	end

end
