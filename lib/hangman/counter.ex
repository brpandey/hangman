defmodule Hangman.Counter do
	defstruct entries: Map.new

	#As of Elixir 1.2 HashDict is deprecated, using Map instead
	
	# Returns new empty Counters
	def new, do: %Hangman.Counter{}
	def new([]), do: %Hangman.Counter{}

	# Returns new Counter that reflects contents of string
	def new(word) when is_binary(word) do 
		add(new(), word) 
	end
	
	# Returns new Counter	that reflects contents of tuple list
	def new(tuple_list) when is_list(tuple_list) and is_tuple(hd(tuple_list)) do
		entries = Enum.into tuple_list, Map.new
		%Hangman.Counter{ entries: entries }
	end

	# Returns an updated Counter
	def add(%Hangman.Counter{entries: entries} = counter, word) do
		
		# Splits word into codepoints list, and then reduces this list into
		# the entries dict, updating the count by one if the key
		# is already present in the entries Map
		 
		entries_updated = 
			Enum.reduce(
				String.codepoints(word), 
				entries, 
				fn head, acc -> Map.update(acc, head, 1, &(&1 + 1)) end
			)

		%Hangman.Counter{ counter | entries: entries_updated }
	end

	# Returns a key-value tuple list of {letter, count} tuples
	def items(%Hangman.Counter{entries: entries} = _counter) do
		Enum.into entries, []
	end

	# Returns list of the most common n codepoints
	def most_common(%Hangman.Counter{entries: entries} = _counter, n) when is_number(n) and n > 0 do
		
		tuple_list = Enum.into entries, []

		#Sort from highest count to lowest count
		tuple_sort_lambda = fn ({_letter_1, x}), ({_letter_2, y})  -> y <= x end

		Enum.sort(tuple_list, tuple_sort_lambda) 
			|> Enum.map( fn ({letter, _count }) -> letter end)	# Just grab the letter
			|> Enum.take(n)
	end

	# Returns an updated Counter
	def del(%Hangman.Counter{entries: entries} = counter, letters) 
	when is_list(letters) and is_binary(hd(letters)) do
		entries_updated = Map.drop(entries, letters)
		%Hangman.Counter{ counter | entries: entries_updated}
	end

end