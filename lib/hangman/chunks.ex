defmodule Hangman.Chunks do
	defstruct key: nil, raw_stream: nil, chunk_count: nil, word_count: nil

	@moduledoc """
		Module to handle Hangman word list chunks for a given length

    Chunks big words list into smaller more manageable list chunks
		Encapsulates raw stream consisting of binary chunks
	"""

  @type t :: %__MODULE__{}
  @type binary_chunk ::  {binary, integer}


	alias Hangman.{Chunks}

  @chunk_words_size 500

  @doc """
  Returns new empty chunks abstraction
  """

  @spec new(pos_integer) :: t
	def new(length_key) when is_number(length_key) and length_key > 0 do
		%Chunks{key: length_key, raw_stream: [], chunk_count: 0, word_count: 0}
	end

  @doc """
  Returns new chunks abstraction, populated with stream encapsulation
  Stream data is split up into chunks and word lists are binaried for
  compactness for storage purposes
  """

  @spec new(pos_integer, Enumerable.t) :: t
  def new(length_key, %Stream{} = words) when is_number(length_key) do
    
    # Take the stream, wrap it with indexes, apply chunking
    # then normalize..

    fn_split_into_chunks = fn
      {_word, index} -> 
        _chunk_id = div(index, @chunk_words_size)
    end

		fn_normalize_chunks = fn 
			chunk -> 
				Enum.map_reduce(chunk, "", 
					fn {word, _index}, _acc -> {word, length_key} end)
		end

		fn_reduce_chunks = fn 
			{word_list, _} = _head, acc ->
	    	bin_chunk = :erlang.term_to_binary(word_list)
	    	chunk_size = Kernel.length(word_list)
	    	value = {bin_chunk, chunk_size}
	    	Chunks.add(acc, value)
    end

    chunks = words
    |> Stream.with_index
    |> Stream.chunk_by(fn_split_into_chunks)
    |> Stream.map(fn_normalize_chunks)
    |> Enum.reduce(Chunks.new(length_key), fn_reduce_chunks)

    chunks
  end

	@doc "Performs constant time lookup of number of words in stream"

  @spec get_count(t, :atom) :: integer
	def get_count(%Chunks{raw_stream: raw_stream} = chunks, :words) do
		if is_nil(raw_stream) do
      raise Hangman.Error, "need to create stream first"
    end
		
		chunks.word_count
	end

	@doc "Performs constant time lookup of number of chunks in stream"

  @spec get_count(t, :atom) :: integer
	def get_count(%Chunks{raw_stream: raw_stream} = chunks, :chunks) do
		if is_nil(raw_stream), do: raise Hangman.Error, "need to create stream first"
		
		chunks.chunk_count
	end

  @doc """
  Returns word length key associated with Chunks abstraction
  """

  @spec get_key(t) :: pos_integer
  def get_key(%Chunks{key: key} = _chunks), do: key

	@doc """
  Takes an existing chunk stream and a tuple value
	The tuple head is a binary chunk and the tail is the number of words
  """

  @spec add(t, binary_chunk) :: t
	def add(%Chunks{raw_stream: raw_stream} = chunks, 
          {binary_chunk, word_count} = _v)
	when is_binary(binary_chunk) and is_number(word_count) 
  and word_count > 0 do

		if is_nil(raw_stream) do
      raise Hangman.Error, "need to invoke new before using add"
    end

		new_stream = Stream.concat(raw_stream, [binary_chunk])

		%Chunks{ chunks | raw_stream: new_stream,
			chunk_count: chunks.chunk_count + 1,
			word_count: chunks.word_count + word_count
		}
	end

  @doc """
  Applies binary unpack function to raw stream then flattens result
  Returns stream of words (un-binaried)
  """

  @spec get_words_lazy(t) :: Enumerable.t
  def get_words_lazy(%Chunks{raw_stream: raw_stream} = _chunks) do
  	Stream.flat_map(raw_stream, &unpack(&1))
  end

  @docp """
  'Unpacks' binary into list of words of type String
  """

  @spec unpack(binary) :: [String.t]
  defp unpack(binary) when is_binary(binary) do
		_words_list = :erlang.binary_to_term(binary)
  end

  @doc """
  Returns chunks information
  """

  @spec info(t) :: Keyword.t
  def info(%Chunks{} = c) do
    [key: get_key(c), count: get_count(c, :words), chunks: get_count(c, :chunks)]
  end

  # Allows users to inspect this module type in a controlled manner  
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Hangman.Chunks.info(t), opts)
      concat ["#Hangman.Chunks<", info, ">"]
    end
  end

end
