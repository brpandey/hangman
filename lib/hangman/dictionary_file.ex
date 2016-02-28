defmodule Hangman.Dictionary.File do

  alias Hangman.Dictionary.File, as: DictFile
	alias Hangman.{Word.Chunks}

 
  # Dictionary path file names
	@dict_normal_path "lib/hangman/data/words.txt"
	@dict_normal_sorted_path "lib/hangman/data/words_sorted.txt"
  @dict_normal_grouped_path "lib/hangman/data/words_grouped.txt"
  @dict_normal_chunked_path "lib/hangman/data/words_chunked.txt"

	@dict_big_path "lib/hangman/data/words_big.txt"
	@dict_big_sorted_path "lib/hangman/data/words_big_sorted.txt"
	@dict_big_grouped_path "lib/hangman/data/words_big_grouped.txt"
	@dict_big_chunked_path "lib/hangman/data/words_big_chunked.txt"

	# Active dictionary paths in use by program
#	@dict_path @dict_big_path
#	@dict_sorted_path @dict_big_sorted_path
#	@dict_grouped_path @dict_big_grouped_path
#	@dict_chunked_path @dict_big_chunked_path

  # Used to delimit chunk values in binary chunks file..
  @chunks_file_delimiter :erlang.term_to_binary({8,1,8,1,8,1})

	# Active dictionary paths in use by program
	@dict_path @dict_normal_path
	@dict_sorted_path @dict_normal_sorted_path
	@dict_grouped_path @dict_normal_grouped_path
	@dict_chunked_path @dict_normal_chunked_path


  # Takes input file, applies a transform type and returns new file path
  # For example, can be used to first sort a file, then upon
  # second invocation, group that file

  def transform(:normal, :sorted) do
    do_transform(@dict_path, @dict_sorted_path, :sorted)
  end

  def transform(path, :sorted, :grouped) do
    do_transform(path, @dict_grouped_path, :grouped)
  end

  def transform(path, :grouped, :chunked) do
    do_transform(path, @dict_chunked_path, :chunked)
  end


	defp do_transform(path, new_path, type) 
	when is_binary(path) and is_binary(new_path) and 
  type in [:sorted, :grouped, :chunked] do

		case File.open(new_path) do
			{:ok, _file} -> new_path
			{:error, :enoent} ->
				{:ok, write_file} = File.open(new_path, [:append])

				fn_write_lambda = fn 
					"\n" ->	nil
					term -> IO.write(write_file, term) 
				end

        fn_write_group_lambda = fn
          {length, index, word} -> 
            IO.puts(write_file, "#{length} #{index} #{word}")
        end

        fn_write_chunk_lambda = fn
          chunk ->
            bin_chunk = :erlang.term_to_binary(chunk)
            IO.binwrite(write_file, bin_chunk)
            # Add delimiter after every chunk, easier for chunk retrieval

            # import of attribute is not working, causing error
            # ** (EXIT) an exception was raised:
            # ** (UndefinedFunctionError) undefined function Hangman.Dictionary.File.Stream.chunks_file_delimiter/0
            #    (play_hangman) Hangman.Dictionary.File.Stream.chunks_file_delimiter()
            # IO.binwrite(write_file, DictFile.Stream.chunks_file_delimiter)
            IO.binwrite(write_file, @chunks_file_delimiter)
        end

        # Process by transform type, then apply transforms
        case type do
          :sorted -> 
				    DictFile.Stream.new(:read_unsorted, path)
				    |> DictFile.Stream.get_data_lazy
					  |> Enum.sort_by(&String.length/1, &<=/2)
					  |> Enum.each(fn_write_lambda)

          :grouped ->
            DictFile.Stream.new(:read_sorted, path)
            |> DictFile.Stream.get_data_lazy
            |> Stream.each(fn_write_group_lambda)
            |> Stream.run

          :chunked ->
            DictFile.Stream.new(:read_grouped, path) 
            |> DictFile.Stream.get_data_lazy
            |> Chunks.Stream.transform(:sorted, :grouped)
            |> Stream.each(fn_write_chunk_lambda)
		        |> Stream.run
          
            _ -> raise Hangman.Error, "Unsupported file transform type"
          
				  File.close(write_file)

		    end
    end
    
    new_path
	end
end
