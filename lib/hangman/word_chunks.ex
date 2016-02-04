defmodule Hangman.Word.Chunks do
	defstruct key: Nil, raw_stream: Nil, chunk_count: Nil, word_count: Nil

	@moduledoc """
		Stream to handle Hangman Word Chunks
		Encapsulates raw stream consisting of binary chunks
	"""

	alias Hangman.{Word.Chunks}

	def new(length_key) when is_number(length_key) and length_key > 0 do
		%Chunks{key: length_key, raw_stream: [], chunk_count: 0, word_count: 0}
	end

	@doc "Performs constant time lookup of number of words in stream"
	def get_count(%Chunks{raw_stream: raw_stream} = chunks, :words) do
		if is_nil(raw_stream), do: raise "need to create stream"
		
		chunks.word_count
	end

	@doc "Performs constant time lookup of number of chunks in stream"
	def get_count(%Chunks{raw_stream: raw_stream} = chunks, :chunks) do
		if is_nil(raw_stream), do: raise "need to create stream"
		
		chunks.chunk_count
	end

	@doc "Takes an existing chunk stream and a tuple value
		The tuple head is a binary chunk and the tuple tail is the number of words"

	def add(%Chunks{raw_stream: raw_stream} = chunks, 
													{binary_chunk, word_count} = _value)
	when is_binary(binary_chunk) and is_number(word_count) and word_count > 0 do

		if is_nil(raw_stream), do: raise "need to invoke new before using add"

		new_stream = Stream.concat(raw_stream, [binary_chunk])

		%Chunks{ chunks | raw_stream: new_stream,
			chunk_count: chunks.chunk_count + 1,
			word_count: chunks.word_count + word_count
		}
	end

  def stream(%Chunks{raw_stream: raw_stream} = _stream) do
    raw_stream    
  end

  def words_list(binary_chunk) when is_binary(binary_chunk) do
		_words_list = :erlang.binary_to_term(binary_chunk)
  end


end
