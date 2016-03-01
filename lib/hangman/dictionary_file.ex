defmodule Hangman.Dictionary.File do

  alias Hangman.Dictionary, as: Dict
	alias Hangman.{Word.Chunks, Dictionary.Attribute.Tokens}

  @type_normal Tokens.type_normal
  @type_big Tokens.type_big

  @unsorted Tokens.unsorted
  @sorted Tokens.sorted
  @grouped Tokens.grouped
  @chunked Tokens.chunked

  @paths Tokens.paths

  @chunks_file_delimiter Tokens.chunks_file_delimiter


  # Takes input file, applies a transform type and returns new file path
  # For example, can be used to first sort a file, then upon
  # second invocation, group that file

  def transform(path, pair = {from, to}, dict_type)
  when is_atom(from) and is_atom(to) and is_atom(dict_type) do

    # assert size_type is valid
    true = dict_type in [@type_normal, @type_big]
    
    # assert from, to pairs are valid
    true = pair in [{@unsorted, @sorted}, 
                    {@sorted, @grouped}, 
                    {@grouped, @chunked}]


    fn_run_transform = fn
      nil, {@unsorted, @sorted}, type ->
        paths_map_by_type = Map.get(@paths, type)
        path = Map.get(paths_map_by_type, :path)
        new_path = Map.get(paths_map_by_type, @sorted)
        do_transform(path, new_path, @sorted)

      path, {_, transform_type}, type when is_binary(path) ->
        paths_map_by_type = Map.get(@paths, type)
        new_path = Map.get(paths_map_by_type, transform_type)
        do_transform(path, new_path, transform_type)
    end

    # retrieve correct paths based on appropriate dictionary type
    # feed paths to do_transform function

    fn_run_transform.(path, {from, to}, dict_type)
  end


	defp do_transform(path, new_path, type) 
	when is_binary(path) and is_binary(new_path) and 
  type in [@sorted, @grouped, @chunked] do

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
            IO.binwrite(write_file, @chunks_file_delimiter)
        end

        # Process by transform type, then apply transforms
        case type do
          @sorted -> 
				    Dict.File.Stream.new({:read, @unsorted}, path)
				    |> Dict.File.Stream.gets_lazy
					  |> Enum.sort_by(&String.length/1, &<=/2)
					  |> Enum.each(fn_write_lambda)

          @grouped ->
            Dict.File.Stream.new({:read, @sorted}, path)
            |> Dict.File.Stream.gets_lazy
            |> Stream.each(fn_write_group_lambda)
            |> Stream.run

          @chunked ->
            Dict.File.Stream.new({:read, @grouped}, path) 
            |> Dict.File.Stream.gets_lazy
            |> Chunks.Stream.transform(@grouped, @chunked)
            |> Stream.each(fn_write_chunk_lambda)
		        |> Stream.run
          
            _ -> raise Hangman.Error, "Unsupported file transform type"
          
				  File.close(write_file)
		    end
    end
    
    new_path
	end
end
