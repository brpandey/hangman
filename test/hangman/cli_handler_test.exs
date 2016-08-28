defmodule Hangman.CLI.Handler.Test do
  use ExUnit.Case

  alias Hangman.{CLI}

  setup_all do
    IO.puts "CLI Handler Test"

    :ok
  end

#  @tag :pending
  @tag timeout: 90_000 # 90 secs
  test "test running 2 human games" do 

    secrets = ["mitochondria", "eject"]
    CLI.Handler.run("jedi_test", :human, secrets, true, true)
  end

  @tag :pending
  test "test running 2 robot games" do 

    secrets = ["asparagus", "voluptuous"]
    CLI.Handler.run("c3po_test", :robot, secrets, false, true)
  end

#  @tag timeout: 90_000 # 90 secs
  @tag :pending
  test "test running 2 human games with player alert" do 

    secrets = ["porcupine", "eel"]
    CLI.Handler.run("photographer_test", :human, secrets, false, true)
  end

end
