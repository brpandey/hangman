
defmodule Hangman.Words.Stream.Test do
	use ExUnit.Case, async: true

	test "test printing 5 dictionary words of variable lengths" do

		path = "lib/hangman/data/words.txt"

		Hangman.Words.Stream.words(:dictionary, path)
			|> Stream.each(&IO.inspect/1)
			|> Enum.take(5)
	end

end