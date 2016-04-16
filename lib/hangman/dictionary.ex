defmodule Hangman.Dictionary do

  @moduledoc """
  Module defines `Dictionary` common attributes and types. 
  Serves as a central point to access or update such attributes

  Used in `Dictionary.Cache`, `Dictionary.File`, `Dictionary.File.Stream`
  """

  @type transform :: :unsorted | :sorted | :grouped | :chunked
  @type kind :: :regular | :big

  @doc "Returns `unsorted` type"
  @spec unsorted :: transform
  def unsorted, do: :unsorted
  
  @doc "Returns `sorted` type"
  @spec sorted :: transform
  def sorted, do: :sorted

  @doc "Returns `grouped` type"
  @spec grouped :: transform
  def grouped, do: :grouped

  @doc "Returns `chunked` type"
  @spec chunked :: transform
  def chunked, do: :chunked

  @doc "Returns `regular` type"
  @spec regular :: kind
  def regular, do: :regular

  @doc "Returns `big` type"
  @spec big :: kind
  def big, do:  :big
  
  @root_path :code.priv_dir(:hangman)

  @doc """
  Returns `Dictionary.File` `paths` map, arranged by types `regular` and `big`
  """
  def paths do
  %{
    :regular => %{
      :path => "#{@root_path}/dictionary/data/words.txt",
      :sorted => "#{@root_path}/dictionary/data/words_sorted.txt",
      :grouped => "#{@root_path}/dictionary/data/words_grouped.txt",
      :chunked => "#{@root_path}/dictionary/data/words_chunked.txt"
    },
    :big => %{
      :path => "#{@root_path}/dictionary/data/words_big.txt",
      :sorted => "#{@root_path}/dictionary/data/words_big_sorted.txt",
      :grouped => "#{@root_path}/dictionary/data/words_big_grouped.txt",
      :chunked => "#{@root_path}/dictionary/data/words_big_chunked.txt"
    }
  }
  end

  @doc "Delimiter `token` used to delimit `chunk` values in `binary` chunks file"
  def chunks_file_delimiter, do: :erlang.term_to_binary({8,1,8,1,8,1})

end
