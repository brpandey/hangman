defmodule Hangman.Web.Flow.Test do
  use ExUnit.Case, async: true



  test "single test of 20 secrets, success when Flow.partition is commented out" do

    secrets = ["JOLLITY", "PEMICANS", "PALPITATION", "UNSILENT", "SUPERPROFITS", "GERUNDIVE", "PILEATE", "OVERAWES", "TUSSORS", "ENDARTERECTOMY", "NONADDITIVE", "WAIVE", "MACHINEABILITY", "COURANTO", "NONOCCUPATIONAL", "SLATED", "REMARKET", "BRACTLET", "SPECTROMETRIC", "OXIDOREDUCTASES"]

    output = Hangman.Web.Flow.run("fox", secrets)

    assert output == " (JOLLITY: 25) (PEMICANS: 7) (PALPITATION: 5) (UNSILENT: 6) (SUPERPROFITS: 4) (GERUNDIVE: 6) (PILEATE: 7) (OVERAWES: 8) (TUSSORS: 6) (ENDARTERECTOMY: 1) (NONADDITIVE: 3) (WAIVE: 25) (MACHINEABILITY: 4) (COURANTO: 6) (NONOCCUPATIONAL: 4) (SLATED: 7) (REMARKET: 6) (BRACTLET: 6) (SPECTROMETRIC: 2) (OXIDOREDUCTASES: 2)"
  end



  test "single test of 5 secrets, success when Flow.partition is commented out" do

    secrets = ["JOLLITY", "PEMICANS", "PALPITATION", "UNSILENT", "SUPERPROFITS"]

    output = Hangman.Web.Flow.run("badger", secrets)

    assert output == " (JOLLITY: 25) (PEMICANS: 7) (PALPITATION: 5) (UNSILENT: 6) (SUPERPROFITS: 4)"

  end


  
  test "single test of 3 secrets for use with stub Pass, success when Flow.partition is commented out" do

    secrets = ["CUMULATE", "AVOCADO", "ERUPTIVE"]

    output = Hangman.Web.Flow.run("rabbit", secrets)

    assert output == " (CUMULATE: 8) (AVOCADO: 6) (ERUPTIVE: 5)"
  end

end
