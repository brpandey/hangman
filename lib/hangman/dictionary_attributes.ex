defmodule Hangman.Dictionary.Attribute.Tokens do

  def unsorted, do: :unsorted
  def sorted, do: :sorted
  def grouped, do: :grouped
  def chunked, do: :chunked

  def type_normal, do: :normal_dictionary
  def type_big, do:  :big_dictionary
 
  # Dictionary file paths
  # arranged by dictionary file sizes normal and big

  def paths do
  %{
    :normal_dictionary => %{
      :path => "lib/hangman/data/words.txt",
	    :sorted => "lib/hangman/data/words_sorted.txt",
      :grouped => "lib/hangman/data/words_grouped.txt",
      :chunked => "lib/hangman/data/words_chunked.txt"
    },
	  :big_dictionary => %{
      :path => "lib/hangman/data/words_big.txt",
	    :sorted => "lib/hangman/data/words_big_sorted.txt",
	    :grouped => "lib/hangman/data/words_big_grouped.txt",
	    :chunked => "lib/hangman/data/words_big_chunked.txt"
    }
  }
  end

  # Used to delimit chunk values in binary chunks file..
  def chunks_file_delimiter, do: :erlang.term_to_binary({8,1,8,1,8,1})

end
