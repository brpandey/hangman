defmodule Hangman.Dictionary.File.Writer do

  @doc """
  Function builder routine to return the customized lambda
  with file handling logic.

  When each returned function runs, it reads in the file, 
  applies the `custom` lambda, and then writes out to the new path
  """

  @spec make_writer((path :: String.t, file :: pid -> String.t)) 
  :: (String.t, String.t -> String.t)
  def make_writer(fn_lambda) do

    # returns a transform lambda, customized to each fn_transform
    fn read_path, write_path ->
      case File.open(write_path) do
        # if transformed file already exists, return file name
        {:ok, _file} -> write_path
        {:error, :enoent} ->

          # get file pid for new transformed file
          {:ok, write_file} = File.open(write_path, [:append])

          # apply lambda arg transformation
          fn_lambda.(read_path, write_file)

          # be a responsible file user
          File.close(write_file)

          # return the "transformed" new path
          write_path
      end
    end
  end

end
