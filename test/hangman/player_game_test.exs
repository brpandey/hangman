defmodule Player.Game.Test do
	use ExUnit.Case

#  alias Hangman.{Player}

  setup_all do
    IO.puts "Player Game Test"
    :ok
  end

  test "test running 2 robot games and 2 human games" do 

		secrets = ["asparagus", "voluptuous"]

    Player.Game.run("c3po", :robot, secrets, false, true)

		secrets = ["mitochondria", "eject"]

    Player.Game.run("jedi", :human, secrets, true, false)

	end
end
