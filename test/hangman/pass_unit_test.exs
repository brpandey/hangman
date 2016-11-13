defmodule Hangman.Pass.UnitTest do
  use ExUnit.Case, async: true

  alias Hangman.{Reduction, Counter, Pass, Words}

  setup context do
    case context[:case_key] do
      :start -> start_round_setup
      :guessing -> guessing_round_setup
    end
  end

  def start_round_setup do

    #### START ROUND 1
    pass_key = {"bernard", 1, 1}
    context = {:start, 8} 
    guessed = []

    reduce_key = Reduction.Options.reduce_key(context, guessed)

    tally = Counter.new(%{"e" => 19600, "s" => 16560, "i" => 15530, "a" => 14490, "r" => 14211, "n" => 12186, "t" => 11870, "o" => 11462, "l" => 11026, "d" => 8046, "c" => 7815, "u" => 7377, "g" => 6009, "m" => 5793, "p" => 5763, "h" => 5111, "b" => 4485, "y" => 3395, "f" => 2897, "k" => 2628, "w" => 2313, "v" => 2156, "z" => 783, "x" => 662, "q" => 422, "j" => 384})

    pass_receipt = %Pass{ size: 28558, tally: tally, last_word: "", possible: ""}

    [pass: pass_receipt, pass_key: pass_key, reduce_key: reduce_key]
  end

  def guessing_round_setup do

    # Run the start round before we do the guessing round so that the proper state is setup

    # setup start round
    [pass: pass_receipt, pass_key: pass_key, reduce_key: reduce_key] =
      start_round_setup

    # run the start round
    {^pass_key, ^pass_receipt} = Pass.result(:start, pass_key, reduce_key)

    #### GUESSING ROUND 2
    pass_key = {"bernard", 1, 2}

    guessed = ["e"]
    regex_key = ~r/^[^e][^e][^e][^e][^e][^e][^e]e$/

    tally = Counter.new(%{"a" => 1215, "i" => 1154, "l" => 940, "o" => 855, "t" => 807, "s" => 689, "r" => 688, "n" => 662, "u" => 548, "c" => 527, "b" => 425, "p" => 387, "m" => 380, "d" => 348, "g" => 280, "h" => 257, "k" => 228, "f" => 169, "v" => 155, "y" => 127, "z" => 112, "w" => 111, "q" => 35, "x" => 24, "j" => 18})

    pass_receipt = %Pass{ last_word: "", size: 1833, tally: tally}

    [pass: pass_receipt, pass_key: pass_key, exclusion: guessed, regex_key: regex_key]
  end


  @tag case_key: :start
  test "pass start", %{pass: pass_receipt, pass_key: pass_key, reduce_key: reduce_key} do

    # Assert pass reduce results!!!
    assert {^pass_key, ^pass_receipt} =
      Pass.result(:start, pass_key, reduce_key)
  end

  
  @tag case_key: :guessing
  test "pass guessing", %{pass: pass_data, pass_key: pass_key, exclusion: exclusion, regex_key: regex_key} do

    # We just perform the computation from pass result :guessing

    # Below is the code contained in the reduce and store routine 
    # in Reduction.Engine.Worker

    # NOTE: Yes we are testing the actual literal code in reduction worker
    #       So yes this is too tight coupling to the implementation details
    #       Since these are the implementation details! But since 
    #       Reduction.Engine worker is a process as is Pass.Cache this makes it 
    #       easier to test this important "KERNEL" code

    # Request word list data from Pass
    data = %Words{} = Pass.Reduction.words(pass_key)

    # REDUCE
    # Create new Words abstraction after filtering out failed word matches
    new_data = %Words{} = data |> Words.filter(regex_key)

    # STORE
    # Write to cache
    pass_receipt = %Pass{} = Pass.Reduction.store(pass_key, new_data, exclusion)

    #IO.puts "pass receipt #{inspect pass_receipt}"
    
    # Assert pass reduce results!!!
    assert ^pass_receipt = pass_data
  end


end
