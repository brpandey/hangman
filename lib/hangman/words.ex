defmodule Hangman.Words do
  @moduledoc """
  Module to manage word lists for a given secret length key.  

  The need for splitting lists arises when we have arbitrary long word
  lists/streams, as it provides structure.

  Module internally maintains standardized `containers` for word lists and 
  keeps track of total word counts. Splits big 
  words list into smaller lists.
  
  A single `Words` abstraction can contain a single word list or 
  multiple lists with sizes info, which is represented as a container.
  
  `Words` provide extra manageability during storage as lists are binaried
  leaving a smaller footprint.
  
  Primary functions are `new/2`, `count/1`, `add/2`, `filter/2`, and `stream/1`.
  """

  alias Hangman.Words

  defstruct key: nil, binary_stream: nil, count: nil
  
  @opaque t :: %__MODULE__{}
  
  @words_container_size Application.get_env(:hangman_game, :words_container_size)
  
  def container_size, do: @words_container_size
  
  @doc """
  Returns new empty `Words` abstraction
  """
  
  @spec new(pos_integer) :: t
  def new(length_key) when is_number(length_key) and length_key > 0 do
    %Words{key: length_key, binary_stream: [], count: 0}
  end
  
  @doc """
  Returns new `Words` abstraction.  Does this by splitting and encapsulating 
  words lists from enumerable into standardized containers.  
  Word lists are binaried for compactness.
  """
  
  @spec new(pos_integer, Enumerable.t) :: t
  def new(length_key, %Stream{} = words) when is_number(length_key) do
    create(length_key, words)
  end


  @doc "Returns total word count across all `Words` containers"
  
  @spec count(t) :: integer
  def count(%Words{binary_stream: binary_stream} = words) do
    if is_nil(binary_stream) do
      raise HangmanError, "need to create stream first"
    end
    
    words.count
  end
  
  
  @doc """
  Returns `Words` word length key
  """
  
  @spec key(t) :: pos_integer
  def key(%Words{key: key} = _words), do: key
  
  @doc """
  Takes an existing `Words` and adds the passed in container `tuple`.
  
  Used in reduce to add a {[binary], count} to the
  `Words` accumulator value.
  
  The `tuple` head is a binaried word list and the tail is the word count
  """
  
  @spec add(t, {[binary], integer}) :: t
  def add(%Words{binary_stream: binary_stream} = words, 
          {binary_list, count} = _value)
  when is_binary(binary_list) and is_number(count) and count > 0 do
    
    if is_nil(binary_stream) do
      raise HangmanError, "need to invoke new before using add"
    end
    
    new_stream = Stream.concat(binary_stream, [binary_list])
    
    %{ words | binary_stream: new_stream,
       count: words.count + count }
  end


  @doc """
  Returns words in `lazy` `enumerable` fashion.
  """

  @spec stream(t) :: Enumerable.t
  def stream(%Words{binary_stream: binary_stream} = _words) do
    binary_stream |> Stream.flat_map(&unpack(&1))
  end

  @doc """
  Return words filtering out words which don't match
  the regex key, returning a new Words abstraction
  """

  @spec filter(t, Regex.t) :: Enumerable.t
  def filter(%Words{key: key} = words, regex_filter_key) do

    filtered = 
      words |> stream |> Stream.filter(&regex_match?(&1, regex_filter_key))

    create(key, filtered)
  end
  
  @doc "Return specified number of words from Words"

  @spec collect(t, pos_integer) :: String.t | [String.t]
  def collect(%Words{} = words, count)
  when is_integer(count) and count > 0 do
    
    list = words |> Words.stream |> Enum.take(count)

    value = 
      case count do
        1 -> list |> List.first
        _ -> list |> Enum.sort
      end
    
    value
  end


  # PRIVATE HELPERS

  # Create new words, given words stream and length key


  @spec create(pos_integer, Enumerable.t) :: t
  defp create(length_key, %Stream{} = words)
  when is_number(length_key) and length_key > 0 do

    # Take the stream, wrap it with indexes, group then normalize..
    
    # lambda to split stream into word lists based on generated grouping id
    # Uses 1 + div() function to group consecutive, sorted words

    # Takes into account the current word index position and 
    # specified container size, to determine grouping id
    
    # A) Example of word stream before grouping
    # {"mugful", 8509}
    # {"muggar", 8510}
    # {"mugged", 8511}
    # {"muggee", 8512}
    
    fn_split_into_containers = fn
      {_word, index} -> 
        _id = div(index, @words_container_size)
    end
    
    # lambda to normalize containers
    # Flatten out / normalize containers so that they contain 
    # only a list of words, and word length size
    
    # B) Example of container, before normalization
    # [{"mugful", 8509}, {"muggar", 8510}, {"mugged", 8511},
    #  {"muggee", ...}, { ...}, {...}, ...]
    
    # Does a Enum.map_reduce, in that the length_key is the acc
    # and the word because the mapped value that is enumerated out
    
    fn_normalize_containers = fn x -> 
        Enum.map_reduce(x, "", fn {word, _index}, _acc -> 
          {word, length_key} 
        end)
    end
    
    # C) Example of container after normalization
    # {["mugful", "muggar", "mugged", "muggee", ...], 6}
    
    fn_reduce_containers = 
      fn {word_list, _} = _head, acc ->
        bin_list = :erlang.term_to_binary(word_list)
        count = Kernel.length(word_list)
        value = {bin_list, count}
        Words.add(acc, value) # Adds to Words abstraction
      end
    
    words
    |> Stream.with_index
    |> Stream.chunk_by(fn_split_into_containers)
    |> Stream.map(fn_normalize_containers)
    |> Enum.reduce(Words.new(length_key), fn_reduce_containers)

  end


  # Helper function to perform actual regex match
  @spec regex_match?(String.t, Regex.t) :: boolean
  defp regex_match?(word, compiled_regex)
  when is_binary(word) and is_nil(compiled_regex) == false do
    Regex.match?(compiled_regex, word)
  end

  # 'Unpacks' binary into list of word strings.
  
  @spec unpack(binary) :: [String.t]
  defp unpack(binary) when is_binary(binary) do
    _words_list = :erlang.binary_to_term(binary)
  end
  

  # Returns `Words` information
  
  @spec info(t) :: Keyword.t
  def info(%Words{} = words) do
    [key: key(words), words: count(words)]
  end
  
  # Allows users to inspect this module type in a controlled manner  

  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.List.inspect(Words.info(t), opts)
      concat ["#Words<", info, ">"]
    end
  end

end
