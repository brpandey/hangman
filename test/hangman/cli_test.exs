defmodule Hangman.CLI.Test do
  use ExUnit.Case, async: true


  test "cli baseline option" do

    command = "-n lulu -t robot -bl"
    argv = String.split(command)
    Hangman.CLI.main(argv)
    
  end

end
