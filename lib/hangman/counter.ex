defmodule Hangman.Counter do
  @moduledoc """

  Module for creating and using letter frequency tallies.
  Contains a set of functions for tallies, such as adding 
  letters, words, lists, and streams, and retrieving their
  most common letters.
  
  Conventional `Hangman` strategy deals exclusively with 
  letter frequency data.
  
  `Counter` is a key value store where a `key` 
  is a letter string and a `value` is a positive integer.

  ## Examples

      iex> tally = Counter.new
      #Counter<[]>

      iex> tally = Counter.add_unique_letters(tally, "mississippi")
      #Counter<[{"i", 1}, {"m", 1}, {"p", 1}, {"s", 1}]>

      iex> Counter.most_common(tally, 5)
      [{"i", 1}, {"m", 1}, {"p", 1}, {"s", 1}]

      iex> tally = Counter.new                                     
      #Counter<[]>

      iex> tally = Counter.add_letters(tally, "mississippi")
      #Counter<[{"i", 4}, {"m", 1}, {"p", 2}, {"s", 4}]>

      iex> Counter.most_common(tally, 5)
      [{"i", 4}, {"s", 4}, {"p", 2}, {"m", 1}]
  """

  alias Hangman.{Chunks, Counter}

  @doc false
  defstruct map: %{}

  @type t :: %__MODULE__{}

  @type key :: String.t
  @type value :: pos_integer

  @chunk_words_size Chunks.container_size

  # Letter Frequency Counter for words
  
  # CREATE

  @spec new(none | String.t | Enumerable.t) :: t

  @doc "Returns new, empty `Counter`"
  def new, do: %Counter{}
  def new([]), do: %Counter{}

  @doc """
  Returns new `Counter` that reflects contents of either `String.t, [tuple], map`
  """
  def new(word) when is_binary(word) do 
    add_letters(new(), word) 
  end
  
  # note: not a keyword list because we are not using atoms for keys, String.t instead
  def new(tuple_list) when is_list(tuple_list) and is_tuple(hd(tuple_list)) do
    map = Enum.into tuple_list, Map.new
    %Counter{ map: map }
  end

  def new(%{} = map) do
    map = Enum.into map, Map.new
    %Counter{ map: map }
  end

  # READ

  @doc "Returns true if `Counters` equal"
  @spec equal?(t, t) :: boolean
  def equal?(%Counter{} = c1, %Counter{} = c2) do
    Map.equal?(c1, c2)
  end

  @doc "Returns `key` list"
  @spec keys(t) :: list
  def keys(%Counter{map: map} = _counter) do
    Map.keys(map)
  end

  @doc "Returns a `key-value` list of {`letter`, `count`} `tuples`"
  @spec items(t) :: [tuple]
  def items(%Counter{map: map} = _counter) do
    Enum.into map, []
  end

  @doc "Returns `true` or `false` whether `Counter` is empty"
  @spec empty?(t) :: boolean
  def empty?(%Counter{map: map} = _counter) do
    Enum.empty?(map)
  end

  @doc "Merges the two counters into one with duplicate keys merged, 
  their values summed"
  
  @spec merge(t, t) :: t
  def merge(%Counter{map: map1}, %Counter{map: map2}) do
    map_merged = Map.merge(map1, map2, fn _k, v1, v2 ->
      v1 + v2
    end)

    Counter.new(map_merged)
  end


  @doc "Returns `list` of the most common `n` codepoint `keys` and codepoint `values`"
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

  @doc "Returns `list` of the most common `n` codepoint `keys`"
  @spec most_common_key(t, pos_integer) :: list
  def most_common_key(%Counter{} = counter, n) 
    when is_number(n) and n > 0 do
    
    most_common(counter, n)
      |> Enum.map( fn ({letter, _count }) -> letter end)  # Just grab the letter key
  end

  # UPDATE

  @doc """
  Increment `value` for a given `key` by the given `value`. 
  Default increment `value` 1.
  """
  @spec inc_by(t, key, none | value) :: t
  def inc_by(%Counter{map: map} = counter, key, value \\ 1)
  when is_binary(key) and is_number(value) and value > 0 do
    %{ counter | map: Map.update(map, key, value, &(&1 + value)) }
  end

  @doc """
  Adds letters to `Counter` without checking for duplicate letters.  
  Returns an updated `Counter`.
  """

  @spec add_letters(t, [] | String.t | Enumerable.t) :: t

  # Handle case where list is empty
  def add_letters(%Counter{} = counter, []), do: counter

  def add_letters(%Counter{} = counter, word) when is_binary(word) do
    add_letters(counter, String.codepoints(word))
  end

  def add_letters(%Counter{map: map} = counter, codepoints) do

    false = Enum.empty?(codepoints)

    # Splits word into codepoints enumerable, 
    # and then reduces this enumerable into
    # the map, updating the count by one if the key
    # is already present in the map, else setting 1 as the initial value

    map_updated = 
      Enum.reduce(
        codepoints,
        map, 
        fn head, acc -> Map.update(acc, head, 1, &(&1 + 1)) end
      )

    %{ counter | map: map_updated }
  end


  @doc """
  Adds letters to `Counter`. Ensure letters are unique. 
  Returns an updated `Counter`
  """

  @spec add_unique_letters(t, String.t | [String.t]) :: t

  def add_unique_letters(%Counter{} = counter, word) 
  when is_binary(word) do
    
    # Splits word into unique codepoints list, 
    # and then reduces this list into
    # the map dict, updating the count by one if the key
    # is already present in the map Map

    add_letters(counter, String.codepoints(word) |> Enum.uniq)
  end

  @doc """
  Adds words `list` to `Counter`. Converts words to char `list` and 
  then letter counts `list`. List is then submitted to `map` for bulk 
  value update. Faster than many tiny `map` updates
  """
  
  @spec add_words(t, words :: Enumerable.t) :: t
  def add_words(%Counter{} = counter, words)
  when is_list(words) do

    fn_reduce_words_into_list = fn
      "", acc -> acc                                    
      word, acc ->
        # using char lists is faster 
        seq = word |> String.to_char_list |> Enum.uniq
        
        # original implementation using codepoint list
        # seq = word |> String.codepoints |> Enum.uniq
        # add_letters(acc, seq)

        # Very efficient ordering with seq first and acc second
        List.flatten(seq, acc)
    end

    # counter = Enum.reduce(words, counter, fn_reduce_word_into_counter)
    
    # 1) Reduce the words into a codepoint sequence list

    # 2) Convert sequence list into letter counts list - faster then bulk map puts!

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
    # using char lists is faster, but have to convert back to String.t

    counter = Enum.reduce(grouped_letter_counts, counter, fn {codepoint_value, value}, acc -> 
      key = :binary.list_to_bin([codepoint_value])
      inc_by(acc, key, value)
    end)

    counter

  end

  @doc """
  Routines adds word `stream` to `Counter`.  Splits word `stream` into 
  manageable `lists`, relies on `add_words/2` to reduce into `Counter`.
  """

  @spec add_words(t, Enumerable.t, Enumerable.t) :: t
  def add_words(%Counter{} = counter, words_stream, exclusion_set) do

    counter = words_stream
    |> Stream.chunk(@chunk_words_size, @chunk_words_size, [])
    |> Enum.reduce(counter, &add_words(&2, &1)) # the acc is the first param, so switch

    
    # Remove exclusion set in one go per word list (vs. per word)
    letters = cond do
      Enum.count(exclusion_set) > 0 ->
        exclusion_set |> Enum.to_list
      true ->
        []
    end
    
    delete(counter, letters)
  end


  # DELETE

  @doc "Returns an updated `Counter` after deleting specified `keys` in letters"
  @spec delete(t, none | [] | [String.t]) :: t

  def delete(%Counter{} = counter, []), do: counter

  def delete(%Counter{map: map} = counter, letters) 
    when is_list(letters) and is_binary(hd(letters)) do

    map_updated = Map.drop(map, letters)
    %{ counter | map: map_updated}
  end

  def delete(%Counter{} = _counter) do
    %Counter{}
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      concat ["#Counter<", Inspect.List.inspect(Counter.items(t), opts), ">"]
    end
  end

end
