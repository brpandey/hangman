defmodule Dictionary do

  @moduledoc """
  Module defines dictionary common attributes and types
  functionality.  Serves as a central point to access or update such attributes
  """

  @type transform :: :unsorted | :sorted | :grouped | :chunked
  @type kind :: :regular | :big

  @doc "Returns unsorted dictionary file type"
  @spec unsorted :: transform
  def unsorted, do: :unsorted
  
  @doc "Returns sorted dictionary file type"
  @spec sorted :: transform
  def sorted, do: :sorted

  @doc "Returns grouped dictionary file type"
  @spec grouped :: transform
  def grouped, do: :grouped

  @doc "Returns chunked dictionary file type"
  @spec chunked :: transform
  def chunked, do: :chunked

  @doc "Returns regular dictionary file type"
  @spec regular :: kind
  def regular, do: :regular

  @doc "Returns big dictionary file type"
  @spec big :: kind
  def big, do:  :big
 
  @doc """
  Returns dictionary file paths map, arranged by dictionary file types regular and big
  """
  def paths do
  %{
    :regular => %{
      :path => "lib/hangman/data/words.txt",
	    :sorted => "lib/hangman/data/words_sorted.txt",
      :grouped => "lib/hangman/data/words_grouped.txt",
      :chunked => "lib/hangman/data/words_chunked.txt"
    },
	  :big => %{
      :path => "lib/hangman/data/words_big.txt",
	    :sorted => "lib/hangman/data/words_big_sorted.txt",
	    :grouped => "lib/hangman/data/words_big_grouped.txt",
	    :chunked => "lib/hangman/data/words_big_chunked.txt"
    }
  }
  end

  @doc "Delimiter token used to delimit chunk values in binary chunks file"
  def chunks_file_delimiter, do: :erlang.term_to_binary({8,1,8,1,8,1})

end
