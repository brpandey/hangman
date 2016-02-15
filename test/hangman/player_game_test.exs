defmodule Hangman.Player.Game.Test do
	use ExUnit.Case

  alias Hangman.{Cache, Player, Supervisor}

  test "test printing each game round through player stream" do 

		{:ok, _pid} = Supervisor.start_link()

		player_name = "julio"
		secrets = ["cumulate", "avocado"]

		_game_server_pid = Cache.get_server(player_name, secrets)

	end
end
