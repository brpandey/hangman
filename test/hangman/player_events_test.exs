defmodule Hangman.Player.Events.Server.Test do
	use ExUnit.Case, async: false

  alias Hangman.{Player.Events}


  setup_all do
    IO.puts "Hangman.Player.Events.Server.Test"
    :ok
  end

  test "inital events server setup" do

    {:ok, epid} = Events.Server.start_link([display_output: true])

    Events.Server.notify_start(epid, "rooster")
    Events.Server.notify_length(epid, {"rooster", 1, 8})

		Events.Server.notify_guess(epid, {:guess_letter, "a"}, {"rooster", 1})
		Events.Server.notify_status(epid, {"rooster", 1, 1, "status"})

		Events.Server.notify_guess(epid, {:guess_letter, "f"}, {"rooster", 1})
		Events.Server.notify_status(epid, {"rooster", 1, 2, "status"})

		Events.Server.notify_guess(epid, {:guess_letter, "e"}, {"rooster", 1})
		Events.Server.notify_status(epid, {"rooster", 1, 3, "status"})

		Events.Server.notify_guess(epid, {:guess_letter, "h"}, {"rooster", 1})
		Events.Server.notify_status(epid, {"rooster", 1, 4, "status"})

		Events.Server.notify_guess(epid, {:guess_letter, "l"}, {"rooster", 1})
		Events.Server.notify_status(epid, {"rooster", 1, 5, "status"})

		Events.Server.notify_guess(epid, {:guess_letter, "k"}, {"rooster", 1})
		Events.Server.notify_status(epid, {"rooster", 1, 6, "status"})

    Events.Server.notify_games_over(epid, "rooster", "game over summary")
  end

end
