defmodule Hangman.Player.Handler.Test do
  use ExUnit.Case

  alias Hangman.{Player}

  setup_all do
    IO.puts "Player Handler Test"

    :ok
  end

  test "test running 2 robot games and 2 human games" do 

    secrets = ["mitochondria", "eject"]

    Player.Handler.run(:cli, "jedi_test", :human, secrets, true, false)


    secrets = ["asparagus", "voluptuous"]

    {:ok, apid} = Player.Alert.Supervisor.start_child("c3po_test", nil)
    Player.Handler.run(:cli, "c3po_test", :robot, secrets, false, true)
    Player.Alert.Handler.stop(apid)

  end

  @tag timeout: 90_000 # 90 secs
  test "test running 2 human games" do 

    secrets = ["porcupine", "eel"]

    {:ok, apid} = Player.Alert.Supervisor.start_child("jedi_test", nil)
    Player.Handler.run(:cli, "photographer_test", :human, secrets, true, true)
    Player.Alert.Handler.stop(apid)
  end

end
