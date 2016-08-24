defmodule Hangman.CLI.Handler.Test do
  use ExUnit.Case

  alias Hangman.{CLI, Player}

  setup_all do
    IO.puts "CLI Handler Test"

    :ok
  end

  test "test running 2 robot games and 2 human games" do 

    secrets = ["mitochondria", "eject"]

    CLI.Handler.run("jedi_test", :human, secrets, true, false)


    secrets = ["asparagus", "voluptuous"]

    {:ok, apid} = Player.Alert.Supervisor.start_child("c3po_test", nil)
    CLI.Handler.run("c3po_test", :robot, secrets, false, true)
    Player.Alert.Handler.stop(apid)

  end

  @tag timeout: 90_000 # 90 secs
  test "test running 2 human games" do 

    secrets = ["porcupine", "eel"]

    {:ok, apid} = Player.Alert.Supervisor.start_child("photographer_test", nil)
    CLI.Handler.run("photographer_test", :human, secrets, true, true)
    Player.Alert.Handler.stop(apid)
  end

end
