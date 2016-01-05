
defmodule Hangman.Dictionary.Test do
	use ExUnit.Case, async: true

	alias Hangman.Dictionary, as: Dictionary

	test "test saying 5 dictionary words of length 10" do

		Dictionary.words(_word_length = 10)		# reader stream
			|> Stream.each(&IO.puts/1)					# printer stream
			|> Stream.each(&Dictionary.say/1)		# speaker stream
			|> Enum.take(5)

	end

end