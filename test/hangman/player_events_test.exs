defmodule Player.Events.Test do
	use ExUnit.Case, async: false


  setup_all do
    IO.puts "Player Events Test"
    :ok
  end

  test "inital events server setup" do

    {:ok, epid} = Player.Events.start_link([display_output: true])

    Player.Events.notify_start(epid, "rooster")
    Player.Events.notify_length(epid, {"rooster", 1, 8})

		Player.Events.notify_guess(epid, {:guess_letter, "a"}, {"rooster", 1})
		Player.Events.notify_status(epid, {"rooster", 1, 1, "status"})

		Player.Events.notify_guess(epid, {:guess_letter, "f"}, {"rooster", 1})
		Player.Events.notify_status(epid, {"rooster", 1, 2, "status"})

		Player.Events.notify_guess(epid, {:guess_letter, "e"}, {"rooster", 1})
		Player.Events.notify_status(epid, {"rooster", 1, 3, "status"})

		Player.Events.notify_guess(epid, {:guess_letter, "h"}, {"rooster", 1})
		Player.Events.notify_status(epid, {"rooster", 1, 4, "status"})

		Player.Events.notify_guess(epid, {:guess_letter, "l"}, {"rooster", 1})
		Player.Events.notify_status(epid, {"rooster", 1, 5, "status"})

		Player.Events.notify_guess(epid, {:guess_letter, "k"}, {"rooster", 1})
		Player.Events.notify_status(epid, {"rooster", 1, 6, "status"})

    Player.Events.notify_games_over(epid, "rooster", "game over summary")
  end

end
