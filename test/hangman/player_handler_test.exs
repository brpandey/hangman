defmodule Hangman.Player.Handler.Test do
  use ExUnit.Case

  alias Hangman.{Player}

  setup_all do
    IO.puts "Player Game Test"
    :ok
  end

  test "test running 2 robot games and 2 human games" do 

    secrets = ["asparagus", "voluptuous"]

    Player.Handler.run("c3po_test", :robot, secrets, false, true)

    secrets = ["mitochondria", "eject"]

    Player.Handler.run("jedi_test", :human, secrets, true, false)
  end

  @tag timeout: 90_000 # 90 secs
  test "test running 2 human games" do 

    secrets = ["porcupine", "eel"]

    Player.Handler.run("photographer_test", :human, secrets, true, true)
  end

end
