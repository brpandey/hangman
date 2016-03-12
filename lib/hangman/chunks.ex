defmodule Chunks do
  defstruct key: nil, raw_stream: nil, chunk_count: nil, word_count: nil
  
  @moduledoc """
  Module to handle word list `Chunks` for a given length key.  
  Internally maintains standardized `containers` for word lists and 
  keeps track of total word counts and number of `containers`.
  
  Splits big words list into smaller more manageable list `Chunks`.
  
  The need for chunking arises when we may have arbitrary long word
  lists/streams, so we chunk the word list to a standard size of 500 words.  
  
  A single `Chunks` abstraction can contain a single chunked word list or 
  multiple chunked word lists.
  
  `Chunks` provide more manageability especially when we store into the database because
  the abstraction automatically binaries data leaving a smaller footprint.
  
  Primary functions are `new/2`, `count/1`, `add/2`, and `get_words_lazy/1`.
  """
  
  @opaque t :: %__MODULE__{}
  @type binary_chunk ::  {binary, integer}
  
  
  @chunk_words_size 500
  
  @spec container_size :: pos_integer
  def container_size, do: @chunk_words_size
  
  @doc """
  Returns new empty `Chunks` abstraction
  """
  
  @spec new(pos_integer) :: t
  def new(length_key) when is_number(length_key) and length_key > 0 do
    %Chunks{key: length_key, raw_stream: [], chunk_count: 0, word_count: 0}
  end
  
  @doc """
  Returns new `Chunks` abstraction.  Does this by splitting and encapsulating 
  words lists from enumerable into standardized `chunk` containers.  
  Word lists are binaried for compactness.
  """
  
  @spec new(pos_integer, Enumerable.t) :: t
  def new(length_key, %Stream{} = words) when is_number(length_key) do
    
    # Take the stream, wrap it with indexes, apply chunking
    # then normalize..
    
    # lambda to split stream into chunks based on generated chunk id
    # Uses 1 + div() function to group consecutive, sorted words
    # Takes into account the current word index position and 
    # specified words-chunk buffer size, to determine chunk id
    
    # A) Example of word stream before chunking
    # {"mugful", 8509}
    # {"muggar", 8510}
    # {"mugged", 8511}
    # {"muggee", 8512}
    
    fn_split_into_chunks = fn
      {_word, index} -> 
        _chunk_id = div(index, @chunk_words_size)
    end
    
    # lambda to normalize chunks
    # Flatten out / normalize chunks so that they contain 
    # only a list of words, and word length size
    
    # B) Example of chunk, before normalization
    # [{"mugful", 8509}, {"muggar", 8510}, {"mugged", 8511},
    #  {"muggee", ...}, { ...}, {...}, ...]
    
    # Does a Enum.map_reduce, in that the length_key is the acc
    # and the word because the mapped value that is enumerated out
    
    fn_normalize_chunks = fn
      chunk -> 
        Enum.map_reduce(chunk, "", 
                        fn {word, _index}, _acc -> {word, length_key} end)
    end
    
    # C) Example of chunk after normalization
    # {["mugful", "muggar", "mugged", "muggee", ...], 6}
    
    fn_reduce_chunks = fn
      {word_list, _} = _head, acc ->
        bin_chunk = :erlang.term_to_binary(word_list)
      chunk_size = Kernel.length(word_list)
      value = {bin_chunk, chunk_size}
      Chunks.add(acc, value) # Adds to Chunks abstraction
    end
    
    chunks = words
    |> Stream.with_index
    |> Stream.chunk_by(fn_split_into_chunks)
    |> Stream.map(fn_normalize_chunks)
    |> Enum.reduce(Chunks.new(length_key), fn_reduce_chunks)
    
    chunks
  end
  
  @doc "Returns total word count across all `chunk` containers"
  
  @spec count(t) :: integer
  def count(%Chunks{raw_stream: raw_stream} = chunks) do
    if is_nil(raw_stream) do
      raise HangmanError, "need to create stream first"
    end
    
    chunks.word_count
  end
  
  @doc "Return total number of `chunk` containers"
  
  @spec size(t) :: integer
  def size(%Chunks{raw_stream: raw_stream} = chunks) do
    if is_nil(raw_stream), do: raise HangmanError, "need to create stream first"
    
    chunks.chunk_count
  end
  
  @doc """
  Returns `Chunks` word length key
  """
  
  @spec key(t) :: pos_integer
  def key(%Chunks{key: key} = _chunks), do: key
  
  @doc """
  Takes an existing `Chunks` and adds the passed in binary `chunk` `tuple`.
  
  Heavily used in reduce methods to add a {binary, word_count} to the
  `Chunks` accumulator value.
  
  The `tuple` head is a binaried word list and the tail is the word count
  """
  
  @spec add(t, binary_chunk) :: t
  def add(%Chunks{raw_stream: raw_stream} = chunks, 
          {binary_chunk, word_count} = _value)
  when is_binary(binary_chunk) and is_number(word_count) 
  and word_count > 0 do
    
    if is_nil(raw_stream) do
      raise HangmanError, "need to invoke new before using add"
    end
    
    new_stream = Stream.concat(raw_stream, [binary_chunk])
    
    %Chunks{ chunks | raw_stream: new_stream,
             chunk_count: chunks.chunk_count + 1,
             word_count: chunks.word_count + word_count
           }
  end
  
  @doc """
  Returns words in `lazy` `enumerable` fashion.
  """
  
  @spec get_words_lazy(t) :: Enumerable.t
  def get_words_lazy(%Chunks{raw_stream: raw_stream} = _chunks) do
    Stream.flat_map(raw_stream, &unpack(&1))
  end
  
  @docp """
  'Unpacks' binary into list of word strings.
  """
  
  @spec unpack(binary) :: [String.t]
  defp unpack(binary) when is_binary(binary) do
    _words_list = :erlang.binary_to_term(binary)
  end
  
  @doc """
  Returns `Chunks` information
  """
  
  @spec info(t) :: Keyword.t
  def info(%Chunks{} = chunks) do
    [key: key(chunks), words: count(chunks), chunks: size(chunks)]
  end
  
  # Allows users to inspect this module type in a controlled manner  
  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.List.inspect(Chunks.info(t), opts)
      concat ["#Chunks<", info, ">"]
    end
  end

end
