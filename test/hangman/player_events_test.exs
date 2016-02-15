defmodule Hangman.Player.Events.Server.Test do
	use ExUnit.Case, async: false

  alias Hangman.{Player.Events}

  test "inital events server setup" do

    {:ok, epid} = Events.Server.start_link([file_output: true])

    Events.Server.notify_start(epid, "rooster")
    Events.Server.notify_length(epid, {"rooster", 1, 8})

		Events.Server.notify_letter(epid, {"rooster", 1, "a"})
		Events.Server.notify_status(epid, {"rooster", 1, 1, "status"})

		Events.Server.notify_letter(epid, {"rooster", 1, "f"})
		Events.Server.notify_status(epid, {"rooster", 1, 2, "status"})

		Events.Server.notify_letter(epid, {"rooster", 1, "e"})
		Events.Server.notify_status(epid, {"rooster", 1, 3, "status"})

		Events.Server.notify_letter(epid, {"rooster", 1, "h"})
		Events.Server.notify_status(epid, {"rooster", 1, 4, "status"})

		Events.Server.notify_letter(epid, {"rooster", 1, "l"})
		Events.Server.notify_status(epid, {"rooster", 1, 5, "status"})

		Events.Server.notify_letter(epid, {"rooster", 1, "k"})
		Events.Server.notify_status(epid, {"rooster", 1, 6, "status"})

    Events.Server.notify_game_over(epid, "rooster", "game over summary")
  end

end
