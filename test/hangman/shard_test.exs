defmodule Hangman.Shard.Test do
  use ExUnit.Case, async: true

  alias Hangman.Shard.Flow

  test "parallel test of 20 secrets" do

    secrets = ["JOLLITY", "PEMICANS", "PALPITATION", "UNSILENT", "SUPERPROFITS", "GERUNDIVE", "PILEATE", "OVERAWES", "TUSSORS", "ENDARTERECTOMY", "NONADDITIVE", "WAIVE", "MACHINEABILITY", "COURANTO", "NONOCCUPATIONAL", "SLATED", "REMARKET", "BRACTLET", "SPECTROMETRIC", "OXIDOREDUCTASES"]

    output = Flow.run("fox", secrets)

    assert output == "Game Over! Average Score: 7.0, # Games: 20, Scores:  (JOLLITY: 25) (PEMICANS: 7) (PALPITATION: 5) (UNSILENT: 6) (SUPERPROFITS: 4) (GERUNDIVE: 6) (PILEATE: 7) (OVERAWES: 8) (TUSSORS: 6) (ENDARTERECTOMY: 1) (NONADDITIVE: 3) (WAIVE: 25) (MACHINEABILITY: 4) (COURANTO: 6) (NONOCCUPATIONAL: 4) (SLATED: 7) (REMARKET: 6) (BRACTLET: 6) (SPECTROMETRIC: 2) (OXIDOREDUCTASES: 2)"
  end



  test "parallel test of 5 secrets" do

    secrets = ["JOLLITY", "PEMICANS", "PALPITATION", "UNSILENT", "SUPERPROFITS"]

    output = Flow.run("badger", secrets)

    assert output == "Game Over! Average Score: 9.4, # Games: 5, Scores:  (JOLLITY: 25) (PEMICANS: 7) (PALPITATION: 5) (UNSILENT: 6) (SUPERPROFITS: 4)"

  end


  
  test "parallel test of 3 secrets - also works well with stub Pass" do

    secrets = ["CUMULATE", "AVOCADO", "ERUPTIVE"]

    output = Flow.run("rabbit", secrets)

    assert output == "Game Over! Average Score: 6.333333333333333, # Games: 3, Scores:  (CUMULATE: 8) (AVOCADO: 6) (ERUPTIVE: 5)"
  end

  test "single test of 1 secret, should see game history" do

    secrets = ["AVOCADO"]

    output = Flow.run("rabbit", secrets)

    assert output == ["-------; score=1; status=KEEP_GUESSING",
            "A---A--; score=2; status=KEEP_GUESSING",
            "A---A--; score=3; status=KEEP_GUESSING",
            "A---A--; score=4; status=KEEP_GUESSING",
            "A---A--; score=5; status=KEEP_GUESSING",
            "A---AD-; score=6; status=KEEP_GUESSING",
            "AVOCADO; score=6; status=GAME_WON",
            "Game Over! Average Score: 6.0, # Games: 1, Scores:  (AVOCADO: 6)"]

  end

end
