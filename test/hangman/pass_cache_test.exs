defmodule Hangman.Pass.Cache.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Pass, Reduction, Letter.Strategy, Counter}

  @robot :robot

  setup_all do
    IO.puts "Pass Cache Test"
    :ok
  end

  test "first full game with 8 rounds of engine reduce, secret is voluptuous, 10 letters" do

    # assume secret word is voluptuous

    #### ROUND 1
    strategy = Strategy.new(:robot)

    pass_key = {id, game_no, round_no} = {"julio", 2, 1}

    context = {:game_start, 10} 

    guessed = Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    tally = Counter.new(%{"a" => 11763, "b" => 3346, "c" => 7431, "d" => 6228, "e" => 15606, "f" => 2227, "g" => 5328, "h" => 4312, "i" => 13788, "j" => 272, "k" => 1380, "l" => 8535, "m" => 5212, "n" => 11339, "o" => 10228, "p" => 5186, "q" => 344, "r" => 11925, "s" => 13226, "t" => 11175, "u" => 5896, "v" => 1906, "w" => 1307, "x" => 585, "y" => 2823, "z" => 899})

    pass_info = %Pass{ size: 20404, tally: tally, last_word: "", possible: ""}

    # Assert pass reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_start}, pass_key, reduce_key)

    IO.puts "Passed initial game start reduce"

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)

    {:guess_letter, "e"} = Strategy.guess(strategy)

    IO.puts "strategy 1a is: #{inspect strategy}\n"

    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "e"}
    
    #### ROUND 2
    pass_key = {id, game_no, round_no = round_no + 1}

    guessed = ["e"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^e]*$/  =
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"a" => 3276, "b" => 820, "c" => 2052, "d" => 1049, "f" => 508, "g" => 1826, "h" => 1137, "i" => 3852, "j" => 79, "k" => 376, "l" => 2273, "m" => 1389, "n" => 2993, "o" => 3157, "p" => 1234, "q" => 60, "r" => 2413, "s" => 2968, "t" => 2750, "u" => 1700, "v" => 271, "w" => 293, "x" => 67, "y" => 1115, "z" => 141})

    pass_info = %Pass{ last_word: "", size: 4798, tally: tally}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "i"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "i"}
    

    # ROUND 3

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["e", "i"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^i]*$/ = 
      Reduction.Options.regex_match_key(context, guessed)


    tally = Counter.new(%{"a" => 733, "b" => 230, "c" => 432, "d" => 267, "f" => 101, "g" => 182, "h" => 333, "j" => 17, "k" => 143, "l" => 434, "m" => 267, "n" => 405, "o" => 774, "p" => 272, "q" => 4, "r" => 631, "s" => 692, "t" => 534, "u" => 415, "v" => 18, "w" => 112, "x" => 12, "y" => 283, "z" => 14})


    pass_info = %Pass{ size: 946, tally: tally, last_word: "", possible: ""}
 
    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "a"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "a"}


    # ROUND 4

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^a]*$/ = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"b" => 42, "c" => 99, "d" => 62, "f" => 38, "g" => 35, "h" => 92, "k" => 34, "l" => 92, "m" => 58, "n" => 90, "o" => 206, "p" => 60, "r" => 141, "s" => 160, "t" => 119, "u" => 134, "v" => 1, "w" => 33, "x" => 2, "y" => 70, "z" => 3})

    pass_info = %Pass{ size: 213, tally: tally, last_word: "", possible: ""}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "o"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "o", "-O-----O--", "-"}


    # ROUND 5

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i", "o"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^aeio]o[^aeio][^aeio][^aeio][^aeio][^aeio]o[^aeio][^aeio]$/ =
      Reduction.Options.regex_match_key(context, guessed)


    possible_txt = "Possible hangman words left, 11 words: [\"combustors\", \"compulsory\", \"conclusory\", \"conductors\", \"consultors\", \"corruptors\", \"nonsupport\", \"polychromy\", \"polygynous\", \"posthumous\", \"voluptuous\"]"


    tally = Counter.new(%{"b" => 1, "c" => 7, "d" => 1, "g" => 1, "h" => 2, "l" => 6, "m" => 4, "n" => 5, "p" => 7, "r" => 8, "s" => 10, "t" => 7, "u" => 10, "v" => 1, "y" => 4})

    pass_info = %Pass{ size: 11, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "s"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "s", "-O-----O-S", "-"}



    # ROUND 6

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i", "o", "s"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^aeios]o[^aeios][^aeios][^aeios][^aeios][^aeios]o[^aeios]s$/ = 
      Reduction.Options.regex_match_key(context, guessed)

 
    tally = Counter.new(%{"c" => 2, "d" => 1, "g" => 1, "l" => 2, "n" => 2, "p" => 3, "r" => 2, "t" => 3, "u" => 4, "v" => 1, "y" => 1})

    possible_txt = "Possible hangman words left, 4 words: [\"conductors\", \"corruptors\", \"polygynous\", \"voluptuous\"]"

    pass_info = %Pass{ size: 4, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "c"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "c"}


    # ROUND 7

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "c", "e", "i", "o", "s"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^c]*$/  = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"g" => 1, "l" => 2, "n" => 1, "p" => 2, "t" => 1, "u" => 2, "v" => 1, "y" => 1})

    possible_txt = "Possible hangman words left, 2 words: [\"polygynous\", \"voluptuous\"]"

    pass_info = %Pass{ size: 2, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "g"} = Strategy.guess(strategy)

    IO.puts "strategy round 7 is: #{inspect strategy}"

    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "g"}



    # ROUND 8

    pass_key = {id, game_no, _round_no = round_no + 1}

    guessed = ["a", "c", "e", "g", "i", "o", "s"]

    assert guessed == Strategy.guessed(strategy)     

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^g]*$/  = 
      Reduction.Options.regex_match_key(context, guessed)


    tally = Counter.new(%{"l" => 1, "p" => 1, "t" => 1, "u" => 1, "v" => 1})

    pass_info = %Pass{ size: 1, tally: tally, last_word: "voluptuous", possible: ""}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_word, "voluptuous"} = Strategy.guess(strategy)
  end

  test "another game with 8 rounds of engine reduce, secret is cumulate, 8 letters" do

    # assume secret word is cumulate


    #### ROUND 1
    strategy = Strategy.new(:robot)

    pass_key = {id, game_no, round_no} = {"julio", 1, 1}

    context = {:game_start, 8} 

    guessed = Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    tally = Counter.new(%{"e" => 19600, "s" => 16560, "i" => 15530, "a" => 14490, "r" => 14211, "n" => 12186, "t" => 11870, "o" => 11462, "l" => 11026, "d" => 8046, "c" => 7815, "u" => 7377, "g" => 6009, "m" => 5793, "p" => 5763, "h" => 5111, "b" => 4485, "y" => 3395, "f" => 2897, "k" => 2628, "w" => 2313, "v" => 2156, "z" => 783, "x" => 662, "q" => 422, "j" => 384})

    pass_info = %Pass{ size: 28558, tally: tally, last_word: "", possible: ""}

    # Assert pass reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_start}, pass_key, reduce_key)

    IO.puts "Passed initial game start reduce"


    # Choose guess
    strategy = Strategy.update(strategy, pass_info)

    {:guess_letter, "e"} = Strategy.guess(strategy)

    IO.puts "strategy 1c is: #{inspect strategy}\n"

    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "e", "-------E", "-"}
    

    #### ROUND 2
    pass_key = {id, game_no, round_no = round_no + 1}

    guessed = ["e"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^e][^e][^e][^e][^e][^e][^e]e$/  =
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"a" => 1215, "i" => 1154, "l" => 940, "o" => 855, "t" => 807, "s" => 689, "r" => 688, "n" => 662, "u" => 548, "c" => 527, "b" => 425, "p" => 387, "m" => 380, "d" => 348, "g" => 280, "h" => 257, "k" => 228, "f" => 169, "v" => 155, "y" => 127, "z" => 112, "w" => 111, "q" => 35, "x" => 24, "j" => 18})

    pass_info = %Pass{ last_word: "", size: 1833, tally: tally}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "a"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "a", "-----A-E", "-"}
    

    # ROUND 3

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^ae][^ae][^ae][^ae][^ae]a[^ae]e$/ = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"t" => 162, "i" => 121, "o" => 108, "u" => 97, "r" => 94, "l" => 89, "s" => 86, "c" => 78, "g" => 63, "n" => 58, "p" => 55, "m" => 50, "b" => 44, "d" => 36, "f" => 28, "h" => 25, "k" => 19, "v" => 13, "w" => 11, "y" => 4, "j" => 3, "x" => 2, "z" => 2, "q" => 1})

    pass_info = %Pass{ size: 236, tally: tally, last_word: "", possible: ""}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "t"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "t", "-----ATE", "-"}


    # ROUND 4

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "t"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^aet][^aet][^aet][^aet][^aet]ate$/ = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"i" => 43, "o" => 42, "u" => 40, "l" => 35, "c" => 29, "n" => 27, "r" => 24, "s" => 20, "m" => 17, "b" => 15, "p" => 13, "d" => 12, "h" => 9, "g" => 9, "v" => 6, "f" => 6, "j" => 3, "y" => 2, "k" => 2, "x" => 1, "z" => 1, "w" => 1})

    pass_info = %Pass{ size: 79, tally: tally, last_word: "", possible: ""}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "o"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "o"}


    # ROUND 5

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "o", "t"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^o]*$/  =
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"u" => 29, "i" => 24, "l" => 16, "n" => 13, "c" => 12, "s" => 12, "r" => 10, "g" => 8, "m" => 7, "p" => 7, "b" => 6, "d" => 5, "f" => 4, "h" => 3, "j" => 3, "v" => 2, "y" => 2, "k" => 1, "x" => 1, "z" => 1})

    possible_txt = "Possible hangman words left, 37 words: [\"bijugate\", \"bunkmate\", \"crispate\", \"cruciate\", \"cumulate\", \"cupulate\", \"figurate\", \"fluxgate\", \"fumigate\", \"incubate\", \"incudate\", \"indicate\", \"indurate\", \"insulate\", \"inundate\", \"irrigate\", \"jubilate\", \"jugulate\", \"ligulate\", \"lunulate\", \"muricate\", \"pyruvate\", \"ruminate\", \"scyphate\", \"shipmate\", \"sibilate\", \"silicate\", \"simulate\", \"subulate\", \"sufflate\", \"sulphate\", \"supinate\", \"suricate\", \"uncinate\", \"undulate\", \"ungulate\", \"vizirate\"]"

    pass_info = %Pass{ size: 37, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "i"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :incorrect_letter, "i"}




    # ROUND 6

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i", "o", "t"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^i]*$/ = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"u" => 12, "l" => 10, "n" => 4, "p" => 4, "s" => 4, "c" => 3, "g" => 3, "b" => 2, "f" => 2, "h" => 2, "m" => 2, "y" => 2, "d" => 1, "k" => 1, "j" => 1, "r" => 1, "v" => 1, "x" => 1})


    possible_txt = "Possible hangman words left, 13 words: [\"bunkmate\", \"cumulate\", \"cupulate\", \"fluxgate\", \"jugulate\", \"lunulate\", \"pyruvate\", \"scyphate\", \"subulate\", \"sufflate\", \"sulphate\", \"undulate\", \"ungulate\"]"

    pass_info = %Pass{ size: 13, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "l"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "l", "----LATE", "-"}


    # ROUND 7

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "e", "i", "l", "o", "t"]

    assert guessed == Strategy.guessed(strategy)

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^[^aeilot][^aeilot][^aeilot][^aeilot]late$/  = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"u" => 7, "c" => 2, "g" => 2, "n" => 2, "s" => 2, "b" => 1, "d" => 1, "f" => 1, "j" => 1, "m" => 1, "p" => 1})

    possible_txt =  "Possible hangman words left, 7 words: [\"cumulate\", \"cupulate\", \"jugulate\", \"subulate\", \"sufflate\", \"undulate\", \"ungulate\"]"

    pass_info = %Pass{ size: 7, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "c"} = Strategy.guess(strategy)

    IO.puts "strategy round 7 is: #{inspect strategy}"

    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "c", "C---LATE", "-"}



    # ROUND 8

    pass_key = {id, game_no, round_no = round_no + 1}
    guessed = ["a", "c", "e", "i", "l", "o", "t"]

    assert guessed == Strategy.guessed(strategy)     

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^c[^aceilot][^aceilot][^aceilot]late$/  = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"u" => 2, "m" => 1, "p" => 1})

    possible_txt = "Possible hangman words left, 2 words: [\"cumulate\", \"cupulate\"]"

    pass_info = %Pass{ size: 2, tally: tally, last_word: "", possible: possible_txt}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)
    {:guess_letter, "m"} = Strategy.guess(strategy)


    # Game Server Guess results
    context = {:game_keep_guessing, :correct_letter, "m", "C-M-LATE", "-"}

    # ROUND 9

    pass_key = {id, game_no, round_no + 1}
    guessed = ["a", "c", "e", "i", "l", "m", "o", "t"]

    assert guessed == Strategy.guessed(strategy) 

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    assert ~r/^c[^aceilmot]m[^aceilmot]late$/  = 
      Reduction.Options.regex_match_key(context, guessed)

    tally = Counter.new(%{"u" => 1})

    pass_info = %Pass{ size: 1, tally: tally, last_word: "cumulate"}

    # Assert reduce results!!!
    {^pass_key, ^pass_info} = 
      Pass.Cache.get({:pass, :game_keep_guessing}, pass_key, reduce_key)

    # Choose guess
    strategy = Strategy.update(strategy, pass_info)

    {:guess_word, "cumulate"} = Strategy.guess(strategy)

  end

end
