defmodule Dictionary.File do
  @moduledoc """
  Provides abstraction for various `Dictionary` files.

  The original `Dictionary` file is transformed into 
  intermediate files as cached representations of each
  transformation layer. Unless the original file changes, transformation 
  every time isn't necessary since the intermediate files are stored on disk.  

  Load time is only determined by the last transformed chunk file, 
  which is optimized for `ETS` load.

  Transformation types are `unsorted` to `sorted`, 
  `sorted` to `grouped`, and `grouped` to `chunked`.  Each transform handler 
  encapsulates each transform procedure
  """

  alias Dictionary, as: Dict

  # Dictionary attribute tokens
  @regular Dict.regular
  @big Dict.big

  @unsorted Dict.unsorted
  @sorted Dict.sorted
  @grouped Dict.grouped
  @chunked Dict.chunked

  @paths Dict.paths
  @chunks_file_delimiter Dict.chunks_file_delimiter


  @doc """
  Takes input file, applies a `transform` and returns new file path.
  For example, can be used to first `sort` a file, then upon
  second invocation, `group` that file.
  """

  @spec transform(path :: String.t, pair :: {Dict.transform, Dict.transform}, 
                  kind :: Dict.kind) :: String.t
  def transform(path, pair = {from, to}, kind)
  when is_atom(from) and is_atom(to) and is_atom(kind) do

    # assert size_type is valid
    true = kind in [@regular, @big]
    
    # assert from, to pairs are valid
    true = pair in [{@unsorted, @sorted}, 
                    {@sorted, @grouped}, 
                    {@grouped, @chunked}]

    # retrieve correct paths based on appropriate dictionary type
    # feed paths to transform_handler function

    fn_run_transform = fn
      nil, {@unsorted, @sorted}, type -> # handle the starting case

        # Get the paths map from Attributes
        paths_map_by_type = Map.get(@paths, type)
        # Get specific type paths map
        path = Map.get(paths_map_by_type, :path)
        # Get entry for type
        new_path = Map.get(paths_map_by_type, @sorted)
        # Send off for actual transform
        transform_handler(path, new_path, @sorted)

      path, {_, transform_type}, type when is_binary(path) -> # generic case

        # Get the paths map from Attributes
        paths_map_by_type = Map.get(@paths, type)
        # Get specific type paths map
        new_path = Map.get(paths_map_by_type, transform_type)
        # Send off for actual transform
        transform_handler(path, new_path, transform_type)
    end

    fn_run_transform.(path, {from, to}, kind)
  end

  @doc """
  Function builder routine to return the customized `transform` function.

  When each returned function runs, its reads in the file, 
  applies the `transform` lambda, and then writes out to the new path
  """

  @spec make_file_transform((path :: String.t, file :: pid -> String.t)) 
  :: (String.t, String.t -> String.t)
  def make_file_transform(fn_transform) do

    # returns a transform lambda, customized to each fn_transform
    fn read_path, write_path ->
      case File.open(write_path) do
        # if transformed file already exists, return file name
			  {:ok, _file} -> write_path
			  {:error, :enoent} ->
          # get file pid for new transformed file
          {:ok, write_file} = File.open(write_path, [:append])

          # apply lambda arg transformation
          fn_transform.(read_path, write_file)

          # be a responsible file user
				  File.close(write_file)

          # return the "transformed" new path
          write_path
      end
    end
  end


  @doc "Specific handler implementations for `sort`, `group`, and `chunk` transform"
  @spec transform_handler(String.t, String.t, Dict.transform) :: String.t

	def transform_handler(path, new_path, @sorted) do

    # called from fn_transform
    fn_write_lambda = fn
      "\n", _ ->	nil
      term, file_pid -> IO.write(file_pid, term) 
		end

    # sort specific transform
    fn_sort = fn
      read_path, file_pid when is_pid(file_pid) ->
        
        Dict.File.Stream.new({:read, @unsorted}, read_path)
        |> Dict.File.Stream.gets_lazy
			  |> Enum.sort_by(&String.length/1, &<=/2)
			  |> Enum.each(&fn_write_lambda.(&1, file_pid))
    end

    # invokes function builder to generate type specific transform    
    sort_transform = make_file_transform(fn_sort)

    # runs transform
    new_path = sort_transform.(path, new_path)
    
    new_path
	end

  # specific handler for group transform

	def transform_handler(path, new_path, @grouped) do

    # called from fn_transform
    fn_write_lambda = fn
      {length, index, word}, file_pid -> 
        IO.puts(file_pid, "#{length} #{index} #{word}")
    end

    # group specific transform
    fn_group = fn
      read_path, file_pid when is_pid(file_pid) ->

        Dict.File.Stream.new({:read, @sorted}, read_path)
        |> Dict.File.Stream.gets_lazy
		    |> Stream.each(&fn_write_lambda.(&1, file_pid))
        |> Stream.run
		end
  
    # invokes function builder to generate type specific transform    
    group_transform = make_file_transform(fn_group)

    # runs transform
    new_path = group_transform.(path, new_path)

    new_path
	end

  # specific handler for chunk transform

	def transform_handler(path, new_path, @chunked) do

    # called from fn_transform
    fn_write_lambda = fn
      chunk, file_pid ->
        bin_chunk = :erlang.term_to_binary(chunk)
        IO.binwrite(file_pid, bin_chunk)
      
        # Add delimiter after every chunk, easier for chunk retrieval
        IO.binwrite(file_pid, @chunks_file_delimiter)
    end

    # chunk specific transform
    fn_chunk = fn
      read_path, file_pid when is_pid(file_pid) ->
        
        Dict.File.Stream.new({:read, @grouped}, read_path) 
        |> Dict.File.Stream.gets_lazy
        |> Chunks.Stream.transform(@grouped, @chunked)
		    |> Stream.each(&fn_write_lambda.(&1, file_pid))
		    |> Stream.run      
		end

    # invokes function builder to generate type specific transform    
    chunk_transform = make_file_transform(fn_chunk)

    # runs transform
    new_path = chunk_transform.(path, new_path)
        
    new_path
	end

end
