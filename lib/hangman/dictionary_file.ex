defmodule Hangman.Dictionary.File do

  alias Hangman.Dictionary.File, as: DictFile
	alias Hangman.{Word.Chunks}


  @normal :normal_dictionary
  @big :big_dictionary
 
  # Dictionary path file names 
  # arranged by dictionary file sizes normal and big

	@normal_paths %{
    :path => "lib/hangman/data/words.txt",
	  :sorted_path => "lib/hangman/data/words_sorted.txt",
    :grouped_path => "lib/hangman/data/words_grouped.txt",
    :chunked_path => "lib/hangman/data/words_chunked.txt"
  }

	@big_paths %{
    :path => "lib/hangman/data/words_big.txt",
	  :sorted_path => "lib/hangman/data/words_big_sorted.txt",
	  :grouped_path => "lib/hangman/data/words_big_grouped.txt",
	  :chunked_path => "lib/hangman/data/words_big_chunked.txt"
  }

  # Used to delimit chunk values in binary chunks file..
  @chunks_file_delimiter :erlang.term_to_binary({8,1,8,1,8,1})

  # Takes input file, applies a transform type and returns new file path
  # For example, can be used to first sort a file, then upon
  # second invocation, group that file

  def transform(:sorted, @normal) do
    path = Map.get(@normal_paths, :path)
    sorted_path = Map.get(@normal_paths, :sorted_path)
    do_transform(path, sorted_path, :sorted)
  end

  def transform(:sorted, @big) do
    path = Map.get(@big_paths, :path)
    sorted_path = Map.get(@big_paths, :sorted_path)
    do_transform(path, sorted_path, :sorted)
  end


  def transform(path, :sorted, :grouped, @normal)
  when is_binary(path) do
    grouped_path = Map.get(@normal_paths, :grouped_path)
    do_transform(path, grouped_path, :grouped)
  end

  def transform(path, :sorted, :grouped, @big)
  when is_binary(path) do
    grouped_path = Map.get(@big_paths, :grouped_path)
    do_transform(path, grouped_path, :grouped)
  end


  def transform(path, :grouped, :chunked, @normal)
  when is_binary(path) do
    chunked_path = Map.get(@normal_paths, :chunked_path)
    do_transform(path, chunked_path, :chunked)
  end

  def transform(path, :grouped, :chunked, @big)
  when is_binary(path) do
    chunked_path = Map.get(@big_paths, :chunked_path)
    do_transform(path, chunked_path, :chunked)
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
