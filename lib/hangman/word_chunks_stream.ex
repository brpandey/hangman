defmodule Hangman.Word.Chunks.Stream do

	# A chunk contains at most 2_000 words
	@chunk_words_size 2_000

  def transform(stream, :sorted, :grouped) do

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
			{length_group, group_index, _} -> 
				_chunk_id = length_group * ( 1 + div(group_index, @chunk_words_size))
		end

		# lambda to normalize chunks
		# Flatten out / normalize chunks so that they contain 
    # only a list of words, and word length size

		# B) Example of chunk, before normalization
		#	[{6, "mugful", 8509}, {6, "muggar", 8510}, {6, "mugged", 8511},
		#	 {6, "muggee", ...}, {6, ...}, {...}, ...]

		fn_normalize_chunks = fn 
			chunk -> 
				Enum.map_reduce(chunk, "", 
					fn {length, _, word}, _acc -> {word, length} end)
		end

		#	C) Example of chunk after normalization
		#	{["mugful", "muggar", "mugged", "muggee", ...], 6}


    stream 
    |> Stream.chunk_by(fn_split_into_chunks)
    |> Stream.map(fn_normalize_chunks)

  end

end
