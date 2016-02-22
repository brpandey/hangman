defmodule Hangman.Pass.Server.Stub do 

  alias Hangman.{Counter, Types.Reduction.Pass}

	def read_pass(:game_start, 
		{id, game_no, 1} = pass_key, reduce_key) 
		when is_binary(id) and is_number(game_no) do

		{:ok, true} =	Keyword.fetch(reduce_key, :game_start)
		{:ok, _length_filter_key}  = Keyword.fetch(reduce_key, :secret_length)
		
		simulate_reduce_sequence(pass_key)
	end

	def read_pass(:game_keep_guessing, 
		{id, game_no, round_no} = pass_key, reduce_key)
		when is_binary(id) and is_number(game_no) and is_number(round_no) do


		{:ok, _exclusion_filter_set} = Keyword.fetch(reduce_key, :guessed_letters)
		{:ok, _regex} = Keyword.fetch(reduce_key, :regex_match_key)
	
		simulate_reduce_sequence(pass_key)	
	end


	# Game 1 - word is: cumulate

	def simulate_reduce_sequence({id, 1, 1}) do

		size = 28558

		tally = Counter.new(%{"e" => 19600, "s" => 16560, "i" => 15530, "a" => 14490, "r" => 14211, "n" => 12186, "t" => 11870, "o" => 11462, 
		"l" => 11026, "d" => 8046, "c" => 7815, "u" => 7377, "g" => 6009, "m" => 5793, "p" => 5763, "h" => 5111, "b" => 4485, 
		"y" => 3395, "f" => 2897, "k" => 2628, "w" => 2313, "v" => 2156, "z" => 783, "x" => 662, "q" => 422, "j" => 384})

		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 1, 1}, pass_info}
	end

	def simulate_reduce_sequence({id, 1, 2}) do

		size = 1833

		tally = Counter.new(%{"a" => 1215, "i" => 1154, "l" => 940, "o" => 855, "t" => 807, "s" => 689, "r" => 688, "n" => 662, "u" => 548, 
		"c" => 527, "b" => 425, "p" => 387, "m" => 380, "d" => 348, "g" => 280, "h" => 257, "k" => 228, "f" => 169, 
		"v" => 155, "y" => 127, "z" => 112, "w" => 111, "q" => 35, "x" => 24, "j" => 18})


		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["e"]
		_guess_letter = "a"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 1, 2}, pass_info}
	end

	def simulate_reduce_sequence({id, 1, 3}) do

		size = 236

		tally = Counter.new(%{"t" => 162, "i" => 121, "o" => 108, "u" => 97, "r" => 94, "l" => 89, "s" => 86, "c" => 78, "g" => 63, "n" => 58, "p" => 55, "m" => 50, "b" => 44, "d" => 36, "f" => 28, "h" => 25, "k" => 19, "v" => 13, "w" => 11, "y" => 4, "j" => 3, "x" => 2, "z" => 2, "q" => 1})


		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e"]
		_guess_letter = "t"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 1, 3}, pass_info}
	end

	def simulate_reduce_sequence({id, 1, 4}) do

		size = 79

		tally = Counter.new(%{"i" => 43, "o" => 42, "u" => 40, "l" => 35, "c" => 29, "n" => 27, "r" => 24, "s" => 20, "m" => 17, "b" => 15, "p" => 13, "d" => 12, "h" => 9, "g" => 9, "v" => 6, "f" => 6, "j" => 3, "y" => 2, "k" => 2, "x" => 1, "z" => 1, "w" => 1})

		#_possible = ["OBDURATE", "NOMINATE", "INDICATE", "INUNDATE", "IRRIGATE", "CORONATE", "CRISPATE", "CONFLATE", "ROOMMATE", "DOMINATE", "SULPHATE", "JUBILATE", "IODINATE", "BIJUGATE", "SIMULATE", "WORKMATE", "SUBULATE", "IMMOLATE", "FUMIGATE", "SIBILATE", "SUPINATE", "INVOCATE", "MOSCHATE", "CHORDATE", "INSOLATE", "INCUDATE", "COPULATE", "ROSULATE", "OPPILATE", "BLOVIATE", "CRUCIATE", "CHLORATE", "COHOBATE", "PYRUVATE", "ORDINATE", "COINMATE", "BUNKMATE", "POPULATE", "INCHOATE", "SHIPMATE", "INNOVATE", "BILOBATE", "UNORNATE", "COLOCATE", "SORORATE", "UMBONATE", "CLODPATE", "VIZIRATE", "LOCULATE", "OBLIGATE", "MODULATE", "SCYPHATE", "INSULATE", "SILICATE", "UNCINATE", "CUPULATE", "SUBOVATE", "CUMULATE", "UNGULATE", "FIGURATE", "UNDULATE", "LORICATE", "LIGULATE", "MURICATE", "SPOLIATE", "FLUXGATE", "LUNULATE", "PRIORATE", "LOBULATE", "JUGULATE", "BIFORATE", "SUFFLATE", "SONICATE", "OSCULATE", "RUMINATE", "INDURATE", "INCUBATE", "CHROMATE", "SURICATE"]
		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "t"]

		_guess_letter = "o"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 1, 4}, pass_info}		
	end

	def simulate_reduce_sequence({id, 1, 5}) do

		size = 37

		tally = Counter.new(%{"u" => 29, "i" => 24, "l" => 16, "n" => 13, "c" => 12, "s" => 12, 
											"r" => 10, "g" => 8, "m" => 7, "p" => 7, "b" => 6, "d" => 5, "f" => 4, 
											"h" => 3, "j" => 3, "v" => 2, "y" => 2, "k" => 1, "x" => 1, "z" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "o", "t"]

		_guess_letter = "i"
		
		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 1, 5}, pass_info}		
	end

	def simulate_reduce_sequence({id, 1, 6}) do

		size = 13

		tally = Counter.new(%{"u" => 12, "l" => 10, "n" => 4, "p" => 4, "s" => 4, "c" => 3, "g" => 3, "b" => 2, "f" => 2, "h" => 2, "m" => 2, "y" => 2, "d" => 1, "k" => 1, "j" => 1, "r" => 1, "v" => 1, "x" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "i", "o", "t"]
	
		_guess_letter = "l"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 1, 6}, pass_info}		
	end

	def simulate_reduce_sequence({id, 1, 7}) do

		size = 7

		tally = Counter.new(%{"u" => 7, "c" => 2, "g" => 2, "n" => 2, "s" => 2, "b" => 1, "d" => 1, "f" => 1, "j" => 1, "m" => 1, "p" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "e", "i", "l", "o", "t"]

    _guess_letter = "c"

		pass_info = %Pass{ size: size, tally: tally, last_word: "" }

		{{id, 1, 7}, pass_info}		
	end

	def simulate_reduce_sequence({id, 1, 8}) do

		size = 2

		tally = Counter.new(%{"u" => 2, "m" => 1, "p" => 1})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "c", "e", "i", "l", "o", "t"]

		_guess_letter = "m"

		pass_info = %Pass{ size: size, tally: tally, last_word: "" }

		{{id, 1, 8}, pass_info}		
	end

	def simulate_reduce_sequence({id, 1, 9}) do

		size = 1

		tally = Counter.new(%{"u" => 2})

		#_possible = ["CUMULATE"]
		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = ["a", "c", "e", "i", "l", "m", "o", "t"]

		_guess_word = "cumulate"

		pass_info = %Pass{ size: size, tally: tally, last_word: "cumulate" }

		{{id, 1, 9}, pass_info}		
	end



	# Game 2, word is: avocado

	def simulate_reduce_sequence({id, 2, 1}) do
		
		size = 23208

		tally = Counter.new(%{"e" => 15273, "s" => 12338, "i" => 11028, "a" => 10830, 
			"r" => 10516, "n" => 8545, "t" => 8034, "o" => 7993, "l" => 7946, "d" => 5995, 
			"u" => 5722, "c" => 5341, "g" => 4590, "p" => 4308, "m" => 4181, "h" => 3701, 
			"b" => 3292, "y" => 2564, "f" => 2115, "k" => 2100, "w" => 1827, "v" => 1394, 
			"z" => 611, "x" => 504, "j" => 412, "q" => 301})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = []
		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 1}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 2}) do

		size = 7395

		tally = Counter.new(%{"i" =>  4824, "a" =>  4607, "s" =>  4139, "n" =>  3721, "o" =>  3632,
		 "r" =>  2819, "l" =>  2779, "t" =>  2699, "u" =>  2432, "g" =>  2228, "c" =>  2048, 
		 "m" =>  1694, "p" =>  1537, "h" =>  1522, "d" =>  1490, "y" =>  1364, "b" =>  1252, "k" =>  816, 
		 "f" =>  815, "w" =>  648, "v" =>  312, "z" =>  206, "j" =>  159, "x" =>  143, "q" =>  102})


		_guessed = ["e"]
		_guess_letter = "a"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 2}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 3}) do
		
		size = 48

		tally = Counter.new(%{"s" =>  25, "r" =>  23, "i" =>  20, "n" =>  16, "l" =>  15, "t" =>  13,
		 "o" =>  12, "c" =>  11, "h" =>  11, "m" =>  11, "d" =>  7, "w" =>  7, "y" =>  7, "b" =>  6,
		  "g" =>  6, "p" =>  6, "f" =>  5, "u" =>  5, "k" =>  4, "v" =>  2, "j" =>  1})


		_guessed = ["a", "e"]
		_guess_letter = "s"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 3}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 4}) do

		size = 23

		tally = Counter.new(%{"r" =>  13, "i" =>  11, "c" =>  8, "t" =>  8, "m" =>  7, "o" =>  7,
		 "n" =>  6, "d" =>  5, "l" =>  5, "g" =>  4, "h" =>  4, "p" =>  4, "b" =>  3, "k" =>  3, "w" =>  3,
		 "y" =>  3, "f" =>  2, "u" =>  2, "v" =>  1})

		_guessed = ["a", "e", "s"]
		_guess_letter = "r"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 4}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 5}) do

		size = 10

		tally = Counter.new(%{"i" =>  6, "o" =>  5, "g" =>  4, "m" =>  4, "l" =>  4, "n" =>  4,
		 "t" =>  3, "c" =>  2, "d" =>  2, "f" =>  2, "p" =>  2, "y" =>  2, "b" =>  1, "h" =>  1,
		 "u" =>  1, "v" =>  1})

		_guessed = ["a", "e", "r", "s"]
		_guess_letter = "i"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 5}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 6}) do

		size = 4

		tally = Counter.new(%{"o" =>  3, "d" =>  2, "m" =>  2, "l" =>  2, "p" =>  2, "y" =>  2,
		 "c" =>  1, "g" =>  1, "n" =>  1, "u" =>  1, "v" =>  1})

		_guessed = ["a", "d", "e", "r", "s"]
		_guess_letter = "d"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 6}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 7}) do

		size = 1

		tally = Counter.new(%{"o" => 2, "v" => 1, "c" => 1})

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: "avocado"}

		{{id, 2, 7}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 8}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 8}, pass_info}
	end

	def simulate_reduce_sequence({id, 2, 9}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 2, 9}, pass_info}
	end



	# Game 3, word is eruptive

	def simulate_reduce_sequence({id, 3, 1}) do
		
		size = 28558

		tally = Counter.new(%{"e" =>  19600, "s" =>  16560, "i" =>  15530, "a" =>  14490, "r" =>  14211,
			"n" =>  12186, "t" =>  11870, "o" =>  11462, "l" =>  11026, "d" =>  8046, "c" =>  7815,
			"u" =>  7377, "g" =>  6009, "m" =>  5793, "p" =>  5763, "h" =>  5111, "b" =>  4485, "y" =>  3395,
			"f" =>  2897, "k" =>  2628, "w" =>  2313, "v" =>  2156, "z" =>  783, "x" =>  662,
			"q" =>  422, "j" =>  384})

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = []
		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 1}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 2}) do

		size = 101

		tally = Counter.new(%{"i" =>  61, "a" =>  56, "l" =>  50, "t" =>  42, "o" =>  34, "s" =>  34,
			"n" =>  31, "c" =>  30, "r" =>  27, "u" =>  23, "p" =>  22, "v" =>  21, "d" =>  20, "g" =>  20,
			"b" =>  18, "m" =>  14, "x" =>  14, "h" =>  12, "y" =>  5, "z" =>  5, "q" =>  4, "k" =>  3, 
			"f" =>  2, "w" =>  1})

		_guessed = ["e"]
		_guess_letter = "a"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 2}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 3}) do
		
		size = 45

		tally = Counter.new(%{"i" =>  36, "o" =>  25, "l" =>  21, "s" =>  19, "c" =>  14,
			"p" =>  14, "r" =>  14, "n" =>  11, "u" =>  11, "t" =>  11, "d" =>  8, "g" =>  8,
			"x" =>  8, "m" =>  7, "v" =>  7, "b" =>  6, "h" =>  4, "y" =>  4, "z" =>  4, 
			"k" =>  3, "f" =>  1, "q" =>  1})

		_guessed = ["a", "e"]
		_guess_letter = "i"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 3}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 4}) do

		size = 14

		tally = Counter.new(%{"o" =>  9, "s" =>  7, "l" =>  6, "u" =>  6, "c" =>  5, "r" =>  5, 
			"g" =>  4, "t" =>  4, "v" =>  4, "n" =>  3, "x" =>  3, "m" =>  2, "p" =>  2, "z" =>  2, 
			"d" =>  1, "f" =>  1, "h" =>  1})

		_guessed = ["a", "e", "i"]
		_guess_letter = "o"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 4}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 5}) do

		size = 5

		tally = Counter.new(%{"u" =>  4, "v" =>  4, "s" =>  3, "r" =>  2, "t" =>  2, "c" =>  1,
		 "d" =>  1, "f" =>  1, "h" =>  1, "m" =>  1, "l" =>  1, "n" =>  1, "p" =>  1})

		_guessed = ["a", "e", "i", "r"]
		_guess_letter = "r"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 5}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 6}) do

		size = 1

		tally = Counter.new(%{"u" => 1, "p" => 1, "t" => 1, "v" => 1})

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: "eruptive"}

		{{id, 3, 6}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 7}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 7}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 8}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 8}, pass_info}
	end

	def simulate_reduce_sequence({id, 3, 9}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 3, 9}, pass_info}
	end



	# Game 4

	def simulate_reduce_sequence({id, 4, 1}) do

		size = 0

		tally = Counter.new

		#_possible = Enum.map(_possible, &String.downcase(&1))

		_guessed = []
		_guess_letter = "e"

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 1}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 2}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 2}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 3}) do
		
		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 3}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 4}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 4}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 5}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 5}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 6}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 6}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 7}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 7}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 8}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 8}, pass_info}
	end

	def simulate_reduce_sequence({id, 4, 9}) do

		size = 0

		tally = Counter.new

		_guessed = []
		_guess_letter = ""

		pass_info = %Pass{ size: size, tally: tally, last_word: ""}

		{{id, 4, 9}, pass_info}
	end

end
