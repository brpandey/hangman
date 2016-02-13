defmodule Hangman.Counter do
  @moduledoc """
  A set of functions for working with letter frequency counters
  Counters are key value stores where keys are letter strings 
  and values are positive integers
  """

  alias Hangman.{Counter}

  @doc false
	defstruct map: %{}

  @opaque t :: %__MODULE__{}

  @type key :: String.t
  @type value :: pos_integer

	# Letter Frequency Counter for words
	
	# CREATE

	# Returns new empty Counters
  
  @spec new :: t
	def new, do: %Counter{}

  @spec new([]) :: t
	def new([]), do: %Counter{}

	# Returns new Counter that reflects contents of string

  @spec new(String.t) :: t
	def new(word) when is_binary(word) do 
		add_letters(new(), word) 
	end
	
	# Returns new Counter	that reflects contents of tuple list
  @spec new(list) :: t
	def new(tuple_list) when is_list(tuple_list) and is_tuple(hd(tuple_list)) do
		map = Enum.into tuple_list, Map.new
		%Counter{ map: map }
	end

	# Returns new Counter	that reflects contents of Map
  @spec new(map) :: t
	def new(%{} = map) do
		map = Enum.into map, Map.new
		%Counter{ map: map }
	end

	# READ

	# Returns true if counters equal
  @spec equal?(t, t) :: boolean
	def equal?(%Counter{} = c1, %Counter{} = c2) do
    Map.equal?(c1, c2)
	end

	# Returns a key-value tuple list of {letter, count} tuples
  @spec items(t) :: [tuple]
	def items(%Counter{map: map} = _counter) do
		Enum.into map, []
	end

	# Quick check to see if Counter is empty
  @spec empty?(t) :: boolean
	def empty?(%Counter{map: map} = _counter) do
		Enum.empty?(map)
	end

	# Returns list of the most common n codepoints and codepoint values
  @spec most_common(t, pos_integer) :: [tuple]
	def most_common(%Counter{map: map} = _counter, n) 
		when is_number(n) and n > 0 do
		
		tuple_list = Enum.into map, []

		#Sort from highest count to lowest count
		tuple_sort_lambda = fn ({_letter_1, x}), ({_letter_2, y})  -> y <= x end

		tuple_list 
			|> Enum.sort(tuple_sort_lambda) 
			|> Enum.take(n)
	end

	# Returns list of the most common n codepoint keys
  @spec most_common_key(t, pos_integer) :: list
	def most_common_key(%Counter{} = counter, n) 
		when is_number(n) and n > 0 do
		
		most_common(counter, n)
			|> Enum.map( fn ({letter, _count }) -> letter end)	# Just grab the letter key
	end

	# UPDATE

	# Increment value for a given key by the given value - default is 1, 
	# if not there add key and value
  @spec inc_by(t, key) :: t
  @spec inc_by(t, key, value) :: t
	def inc_by(%Counter{map: map} = counter, key, value \\ 1)
  when is_binary(key) and is_number(value) and value > 0 do
		%Counter{ counter | map: Map.update(map, key, value, &(&1 + value)) }
	end

	# Returns an updated Counter

	# Handle case where list is empty
  @spec add_letters(t, []) :: t
	def add_letters(%Counter{} = counter, []), do: counter


  @spec add_letters(t, String.t) :: t
  def add_letters(%Counter{} = counter, word) when is_binary(word) do
    add_letters(counter, String.codepoints(word))
  end

  @spec add_letters(t, Enumerable.t) :: t
	def add_letters(%Counter{map: map} = counter, codepoints) do

		false = Enum.empty?(codepoints)

		# Splits word into codepoints enumerable, 
    # and then reduces this enumerable into
		# the map dict, updating the count by one if the key
		# is already present in the map Map, else setting 1 as the initial value

		map_updated = 
			Enum.reduce(
				codepoints,
				map, 
				fn head, acc -> Map.update(acc, head, 1, &(&1 + 1)) end
			)

		%Counter{ counter | map: map_updated }
	end

  @spec add_unique_letters(t, String.t) :: t
	def add_unique_letters(%Counter{} = counter, word) 
	when is_binary(word) do
		
		# Splits word into unique codepoints list, 
    # and then reduces this list into
		# the map dict, updating the count by one if the key
		# is already present in the map Map

		add_letters(counter, String.codepoints(word) |> Enum.uniq)
	end

  @spec add_words(t, [String.t]) :: t
  def add_words(%Counter{} = counter, words)
  when is_list(words) do

    fn_reduce_words_into_list = fn
      "", acc -> acc                                    
      word, acc ->
        # using char lists is faster 
        seq = word |> String.to_char_list |> Enum.uniq
        
        # seq = word |> String.codepoints |> Enum.uniq
        # add_letters(acc, seq)

        List.flatten(seq, acc)
    end

    # counter = Enum.reduce(words, counter, fn_reduce_word_into_counter)
    
    # 1) Reduce the words into a codepoint sequence list

    # 2) Convert sequence list into letter counts list
    # e.g.  the seq is ["a", "b", "d", "h", "d", "b", "b", "h", "a"] 
    # sort  the seq is now ["a", "a", "b", "b", "b", "d", "d", "h", "h"]
    # chunk the seq is now [["a", "a"], ["b", "b", "b"], ["d", "d"], ["h", "h"]]
    # index [[{"a", 1}, {"a", 2}], [{"b", 1}, {"b", 2}, {"b", 3}], 
    #       [{"d", 1}, {"d", 2}], [{"h", 1}, {"h", 2}]]

    # final seq is: [{"a", 2}, {"b", 3}, {"d", 2}, {"h", 2}] 


    grouped_letter_counts = words
    |> Enum.reduce([], fn_reduce_words_into_list)
    |> Enum.sort # O(nlogn)
    |> Enum.chunk_by(&(&1)) # O(n)
    |> Enum.map(&Enum.with_index(&1,1)) # O(n)
    |> Enum.map(&List.last/1) # O(n)

    # allow for batch updating of codepoints vs updating the counter map for every codepoint
    counter = Enum.reduce(grouped_letter_counts, counter, fn {codepoint_value, value}, acc -> 
      key = :binary.list_to_bin([codepoint_value])
      inc_by(acc, key, value)
    end)

    counter

  end

  @spec add_words(t, Enumerable.t, map) :: t
  def add_words(%Counter{} = counter, words_stream, 
                    %MapSet{} = exclusion_set) do

    chunk_size = 500

    counter = words_stream
    |> Stream.chunk(chunk_size, chunk_size, [])
    |> Enum.reduce(counter, &add_words(&2, &1)) # the acc is the first param, so switch

    
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
  @spec delete(t, []) :: t
  def delete(%Counter{} = counter, []), do: counter

  @spec delete(t, [String.t]) :: t
	def delete(%Counter{map: map} = counter, letters) 
		when is_list(letters) and is_binary(hd(letters)) do

		map_updated = Map.drop(map, letters)
		%Counter{ counter | map: map_updated}
	end

  @spec delete(t) :: t
	def delete(%Counter{} = _counter) do
		%Counter{}
	end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(set, opts) do
      concat ["#Hangman.Counter<", Inspect.List.inspect(Hangman.Counter.items(set), opts), ">"]
    end
  end

end
