defmodule Hangman.Player.FSM.Test do
	use ExUnit.Case

  alias Hangman.{Player, Player.FSM}

  setup_all do

		{:ok, _pid} = Hangman.Supervisor.start_link()

    # initialize static params map for test cases
    # track test case with :current_key
    # each test just needs to grab the current player pid
    map = %{
      :current_player_pid => nil,
      :cases => %{
        :robot => [name: "wall_e", type: :robot, secrets: ["cumulate"]],
        :turbo_robot => [name: "turbo_wall_e", type: :robot, secrets: ["cumulate"]],
        :human => [name: "socrates", type: :human, secrets: ["cumulate", "avocado"]]
      }
    }

    {:ok, params: map}
  end

  setup context do

    map = context[:params]
    case_key = context[:case_key]

    cases = Map.get(map, :cases)

    test_case_options = Map.get(cases, case_key)
    
    # fetch the test specific params
    name = Keyword.fetch!(test_case_options, :name)
    secrets = Keyword.fetch!(test_case_options, :secrets)
    type = Keyword.fetch!(test_case_options, :type)

    IO.puts " "

    # Retrieve game server pid given test specific params
    game_pid = Hangman.Cache.get_server(name, secrets)

    # Retrieve player fsm pid through dynamic start
    {:ok, player_pid} = Player.Supervisor.start_child(name, type, game_pid)

    # Update case context params map, for current test
    map = Map.put(map, :current_player_pid, player_pid)

    on_exit fn ->
      Hangman.Player.FSM.stop(player_pid)
      # Hangman.Game.Server.stop(game_pid)
      IO.puts "Test finished"
    end

    {:ok, params: map}

  end

  @tag case_key: :robot
	test "synchronous robot player over 1 game", context do

 	  IO.puts "\n1) Starting regular WALL-e \n"		

    ppid = context[:params] |> Map.get(:current_player_pid)

		#:sys.trace(ppid, true)

		{:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "-------E; score=1; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid) 

    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)	    

    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)
    
    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:game_keep_guessing, reply} = FSM.wall_e_guess(ppid)

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:game_won, reply} = FSM.wall_e_guess(ppid)

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    {:game_over, reply} = FSM.wall_e_guess(ppid)

 	  assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

    {:game_reset, reply} = FSM.wall_e_guess(ppid)

    IO.puts "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)"

    IO.puts "Asserts successfully passed, #{reply}"

 	  #FSM.stop(ppid)

  end

  @tag case_key: :turbo_robot
  test "asynchronous robot player over 1 game", context do

 	  # Game 2 -- ASYNC ROBOT!! turbo wall_e

 	  IO.puts "\n2) Starting turbo WALL-e \n"

    ppid = context[:params] |> Map.get(:current_player_pid)

		#:sys.trace(ppid, true)

		:ok = FSM.turbo_wall_e_guess(ppid)

		# sleep for 2 seconds :)
		receive do
			after 2000 -> nil
		end

		{_, reply} = FSM.sync_status(ppid)

		IO.puts "\nturbo WALL-e status: #{reply}"

    #FSM.stop(ppid)

  end

  @tag case_key: :human
  test "synchronous human player over 2 games", context do

		# Game 3 -- HUMAN!! socrates

 	  IO.puts "\n3) Starting Socrates human guessing player with 2 games \n"		

    ppid = context[:params] |> Map.get(:current_player_pid)

		#:sys.trace(ppid, true)

		{_code, reply} = FSM.socrates_proceed(ppid)

		IO.puts "\nGame 1: #{reply}"			

		{_code, reply} = FSM.socrates_guess(ppid, "e")

		IO.puts "\nGame 1: #{reply}"	

		{_code, reply} = FSM.socrates_guess(ppid, "a")

		IO.puts "\nGame 1: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "t")

		IO.puts "\nGame 1: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "o")

		IO.puts "\nGame 1: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "i")

		IO.puts "\nGame 1: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "l")

		IO.puts "\nGame 1: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "c")

		IO.puts "\nGame 1: #{reply}"

    assert "Possible hangman words left, 2 words: [\"cumulate\", \"cupulate\"]\n\nPlayer socrates, Round 8, C---LATE; score=7; status=KEEP_GUESSING.\n3 weighted letter choices :  u:2 m*:1 p:1 (* robot choice)" = reply

		{_code, reply} = FSM.socrates_guess(ppid, "m")

    assert "Player socrates, Round 9: Last word left: cumulate" = reply

		{_code, reply} = FSM.socrates_win(ppid)

		IO.puts "\nGame 1: #{reply}\n"

		{_code, reply} = FSM.socrates_proceed(ppid)

		IO.puts "\nGame 2: #{reply}"	

		{_code, reply} = FSM.socrates_guess(ppid, "e")

		IO.puts "\nGame 2: #{reply}"		

		{_code, reply} = FSM.socrates_guess(ppid, "a")

		IO.puts "\nGame 2: #{reply}"		

		{_code, reply} = FSM.socrates_guess(ppid, "s")

		IO.puts "\nGame 2: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "r")

		IO.puts "\nGame 2: #{reply}"

		{_code, reply} = FSM.socrates_guess(ppid, "i")

		IO.puts "\nGame 2: #{reply}"	

		{_code, reply} = FSM.socrates_guess(ppid, "d")

		IO.puts "\nGame 2: #{reply}"

		{_code, reply} = FSM.socrates_win(ppid)

		IO.puts "\nGame 2: #{reply}"

		{_code, reply} = FSM.socrates_proceed(ppid)

		IO.puts "\nGame 2: #{reply}"

		{_code, reply} = FSM.socrates_proceed(ppid)

		IO.puts "\nGame 2: #{reply}"

    #FSM.stop(ppid)
	end
end

