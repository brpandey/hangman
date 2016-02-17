defmodule Hangman.Player.Game.Test do
	use ExUnit.Case

  alias Hangman.{Player, Supervisor}

  test "test running 2 robot games and 2 human games" do 

		{:ok, _pid} = Supervisor.start_link()

		secrets = ["cumulate", "avocado"]

    "wall_e"
    |> Player.Game.setup(secrets)
		|> Player.Game.play_rounds_lazy(:robot)		
		|> Stream.each(fn text -> IO.puts("\n#{text}") end)							
		|> Stream.run

    "socrates"
    |> Player.Game.setup(secrets)
    |> Player.Game.play_rounds_lazy(:human)
    |> Stream.each(fn text -> IO.puts("\n#{text}") end)							
	  |> Stream.run
      
	end
end
