defmodule Hangman.Player.Stream.Test do
	use ExUnit.Case

  alias Hangman.{Cache, Player, Supervisor}

  test "test printing each game round through player stream" do 

		{:ok, _pid} = Supervisor.start_link()

		player_name = "julio"
		secrets = ["cumulate", "avocado"]

		game_server_pid = Cache.get_server(player_name, secrets)

		{:ok, notify_pid} = Player.Events.Notify.start_link([display_output: false])

		Player.Stream.get_round_lazy(player_name, game_server_pid, notify_pid)		
    # reader stream
			|> Stream.each(fn text -> IO.puts("\n#{text}") end)							
    # printer stream
			|> Enum.take(100)

	end
end
