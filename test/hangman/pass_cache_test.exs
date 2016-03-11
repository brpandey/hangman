defmodule Pass.Cache.Test do
	use ExUnit.Case #, async: true

  @robot :robot

  setup_all do
    IO.puts "Pass Cache Test"
    :ok
  end

	test "a full game with 8 rounds of engine reduce" do

    # assume secret word is cumulate


    #### ROUND 1
    strategy = Strategy.new

    pass_key = {id, game_no, round_no} = {"julio", 1, 1}

    context = {:game_start, 8} 

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    tally = Counter.new(%{"e" => 19600, "s" => 16560, "i" => 15530, "a" => 14490, "r" => 14211, "n" => 12186, "t" => 11870, "o" => 11462, "l" => 11026, "d" => 8046, "c" => 7815, "u" => 7377, "g" => 6009, "m" => 5793, "p" => 5763, "h" => 5111, "b" => 4485, "y" => 3395, "f" => 2897, "k" => 2628, "w" => 2313, "v" => 2156, "z" => 783, "x" => 662, "q" => 422, "j" => 384})

    pass_info = %Pass{ size: 28558, tally: tally, last_word: "", possible: ""}

    # Assert pass reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_start}, pass_key, reduce_key)

    IO.puts "Passed initial game start reduce"


    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)

    {:guess_letter, "e"} = Strategy.make_guess(strategy)

    IO.puts "strategy 1c is: #{inspect strategy}\n"

    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "e", "-------E", "-"}
    

    #### ROUND 2
    pass_key = {id, game_no, round_no = round_no + 1}

    guessed = ["e"]

		assert guessed == Strategy.get_guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^[^e][^e][^e][^e][^e][^e][^e]e$/  =
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"a" => 1215, "i" => 1154, "l" => 940, "o" => 855, "t" => 807, "s" => 689, "r" => 688, "n" => 662, "u" => 548, "c" => 527, "b" => 425, "p" => 387, "m" => 380, "d" => 348, "g" => 280, "h" => 257, "k" => 228, "f" => 169, "v" => 155, "y" => 127, "z" => 112, "w" => 111, "q" => 35, "x" => 24, "j" => 18})

    pass_info = %Pass{ last_word: "", size: 1833, tally: tally}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "a"} = Strategy.make_guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "a", "-----A-E", "-"}
    

    # ROUND 3

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e"]

		assert guessed == Strategy.get_guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^[^ae][^ae][^ae][^ae][^ae]a[^ae]e$/ = 
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"t" => 162, "i" => 121, "o" => 108, "u" => 97, "r" => 94, "l" => 89, "s" => 86, "c" => 78, "g" => 63, "n" => 58, "p" => 55, "m" => 50, "b" => 44, "d" => 36, "f" => 28, "h" => 25, "k" => 19, "v" => 13, "w" => 11, "y" => 4, "j" => 3, "x" => 2, "z" => 2, "q" => 1})

    pass_info = %Pass{ size: 236, tally: tally, last_word: "", possible: ""}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "t"} = Strategy.make_guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "t", "-----ATE", "-"}


    # ROUND 4

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "t"]

		assert guessed == Strategy.get_guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^[^aet][^aet][^aet][^aet][^aet]ate$/ = 
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"i" => 43, "o" => 42, "u" => 40, "l" => 35, "c" => 29, "n" => 27, "r" => 24, "s" => 20, "m" => 17, "b" => 15, "p" => 13, "d" => 12, "h" => 9, "g" => 9, "v" => 6, "f" => 6, "j" => 3, "y" => 2, "k" => 2, "x" => 1, "z" => 1, "w" => 1})

    pass_info = %Pass{ size: 79, tally: tally, last_word: "", possible: ""}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "o"} = Strategy.make_guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "o"}


    # ROUND 5

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "o", "t"]

		assert guessed == Strategy.get_guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^[^o]*$/  =
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"u" => 29, "i" => 24, "l" => 16, "n" => 13, "c" => 12, "s" => 12, "r" => 10, "g" => 8, "m" => 7, "p" => 7, "b" => 6, "d" => 5, "f" => 4, "h" => 3, "j" => 3, "v" => 2, "y" => 2, "k" => 1, "x" => 1, "z" => 1})

    possible_txt = "Possible hangman words left, 37 words: [\"bijugate\", \"bunkmate\", \"crispate\", \"cruciate\", \"cumulate\", \"cupulate\", \"figurate\", \"fluxgate\", \"fumigate\", \"incubate\", \"incudate\", \"indicate\", \"indurate\", \"insulate\", \"inundate\", \"irrigate\", \"jubilate\", \"jugulate\", \"ligulate\", \"lunulate\", \"muricate\", \"pyruvate\", \"ruminate\", \"scyphate\", \"shipmate\", \"sibilate\", \"silicate\", \"simulate\", \"subulate\", \"sufflate\", \"sulphate\", \"supinate\", \"suricate\", \"uncinate\", \"undulate\", \"ungulate\", \"vizirate\"]"

    pass_info = %Pass{ size: 37, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "i"} = Strategy.make_guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "i"}




    # ROUND 6

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i", "o", "t"]

		assert guessed == Strategy.get_guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^[^i]*$/ = 
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"u" => 12, "l" => 10, "n" => 4, "p" => 4, "s" => 4, "c" => 3, "g" => 3, "b" => 2, "f" => 2, "h" => 2, "m" => 2, "y" => 2, "d" => 1, "k" => 1, "j" => 1, "r" => 1, "v" => 1, "x" => 1})


    possible_txt = "Possible hangman words left, 13 words: [\"bunkmate\", \"cumulate\", \"cupulate\", \"fluxgate\", \"jugulate\", \"lunulate\", \"pyruvate\", \"scyphate\", \"subulate\", \"sufflate\", \"sulphate\", \"undulate\", \"ungulate\"]"

    pass_info = %Pass{ size: 13, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "l"} = Strategy.make_guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "l", "----LATE", "-"}


    # ROUND 7

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i", "l", "o", "t"]

		assert guessed == Strategy.get_guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^[^aeilot][^aeilot][^aeilot][^aeilot]late$/  = 
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"u" => 7, "c" => 2, "g" => 2, "n" => 2, "s" => 2, "b" => 1, "d" => 1, "f" => 1, "j" => 1, "m" => 1, "p" => 1})

    possible_txt =  "Possible hangman words left, 7 words: [\"cumulate\", \"cupulate\", \"jugulate\", \"subulate\", \"sufflate\", \"undulate\", \"ungulate\"]"

    pass_info = %Pass{ size: 7, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "c"} = Strategy.make_guess(strategy)

    IO.puts "strategy round 7 is: #{inspect strategy}"

    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "c", "C---LATE", "-"}



    # ROUND 8

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "c", "e", "i", "l", "o", "t"]

		assert guessed == Strategy.get_guessed(strategy)     

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^c[^aceilot][^aceilot][^aceilot]late$/  = 
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"u" => 2, "m" => 1, "p" => 1})

    possible_txt = "Possible hangman words left, 2 words: [\"cumulate\", \"cupulate\"]"

    pass_info = %Pass{ size: 2, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)
    {:guess_letter, "m"} = Strategy.make_guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "m", "C-M-LATE", "-"}

    # ROUND 9

    pass_key = {id, game_no, round_no + 1}
    guessed = ["a", "c", "e", "i", "l", "m", "o", "t"]

		assert guessed == Strategy.get_guessed(strategy) 

    reduce_key = Reduction.Options.reduce_key(context, strategy.guessed_letters)

    assert ~r/^c[^aceilmot]m[^aceilmot]late$/  = 
      Reduction.Options.regex_match_key(context, guessed)

		tally = Counter.new(%{"u" => 1})

    pass_info = %Pass{ size: 1, tally: tally, last_word: "cumulate"}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info, @robot)

    {:guess_word, "cumulate"} = Strategy.make_guess(strategy)

	end

end
