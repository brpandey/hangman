defmodule Hangman.Player.Worker.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Player, Game}

  setup_all do
    IO.puts "Player Worker Test"

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
      :current_player_pid => nil,
      :cases => %{
        :robot => [name: "wall_e_test", type: :robot, display: true,
                   secrets: ["cumulate"]],
        :human => [name: "socrates_test", type: :human, display: true,
                   secrets: ["cumulate", "avocado"]]
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
    display = Keyword.fetch!(test_case_options, :display)

    # Retrieve game server pid given test specific params
    game_pid = Game.Pid.Cache.get_server_pid(name, secrets)

    # Get event server pid next
    {:ok, lpid} = Player.Logger.Supervisor.start_child(name)
    {:ok, apid} = Player.Alert.Supervisor.start_child(name, nil)

    # Retrieve player fsm pid through dynamic start

    {:ok, player_pid} = 
      Player.Worker.Supervisor.start_child(name, type, display, game_pid)

    # Update case context params map, for current test
    map = Map.put(map, :current_player_pid, player_pid)

    on_exit fn ->
      Player.Logger.Handler.stop(lpid)
      Player.Alert.Handler.stop(apid)
      Player.Worker.stop(player_pid)
      # Hangman.Game.Server.stop(game_pid)
      IO.puts "Player Test finished"
    end

    {:ok, params: map}

  end



  @tag case_key: :robot
  test "synchronous robot player over 1 game", context do

    IO.puts "\n1) Starting regular WALL-e \n"   

    ppid = context[:params] |> Map.get(:current_player_pid)

    #:sys.trace(ppid, true)

    {:begin, _reply} = ppid |> Player.Worker.proceed
    {:action, reply} = ppid |> Player.Worker.proceed

    assert "-------E; score=1; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed 

    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed      

    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed
    
    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed

    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed

    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.Worker.proceed

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    {:transit, reply} = ppid |> Player.Worker.proceed

    assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

    IO.puts reply

    {:exit, reply} = ppid |> Player.Worker.proceed

    assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

    IO.puts reply

  end


  @tag case_key: :human
  test "synchronous human player over 2 games", context do

    # Game 3 -- HUMAN!! socrates

    IO.puts "\n3) Starting Socrates human guessing player with 2 games \n"    

    ppid = context[:params] |> Map.get(:current_player_pid)

    #:sys.trace(ppid, true)

    {:begin, reply} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1a: #{inspect reply}"      

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1b: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("e")

    IO.puts "\nGame 1c: #{inspect reply}"  

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1d: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("a")

    IO.puts "\nGame 1e: #{inspect reply}"

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1f: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("t")

    IO.puts "\nGame 1g: #{inspect reply}"

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1h: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("o")

    IO.puts "\nGame 1i: #{inspect reply}"

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1j: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("i")

    IO.puts "\nGame 1k: #{inspect reply}"

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1l: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("l")

    IO.puts "\nGame 1m: #{inspect reply}"

    {:setup, setup} = ppid |> Player.Worker.proceed

    assert [display: true, status: {:guess_letter, "Possible hangman words left, 7 words: [\"cumulate\", \"cupulate\", \"jugulate\", \"subulate\", \"sufflate\", \"undulate\", \"ungulate\"]\n\nPlayer socrates_test, Round 7, ----LATE; score=6; status=KEEP_GUESSING.\n5 weighted letter choices :  u:7 c*:2 g:2 n:2 s:2 (* robot choice)"}] = setup

    IO.puts "\nGame 1n: #{inspect setup}"  

    {:action, reply} = ppid |> Player.Worker.guess("c")

    IO.puts "\nGame 1o: #{inspect reply}"

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1p: #{inspect setup}"  

    assert [display: true, status: {:guess_letter, "Possible hangman words left, 2 words: [\"cumulate\", \"cupulate\"]\n\nPlayer socrates_test, Round 8, C---LATE; score=7; status=KEEP_GUESSING.\n3 weighted letter choices :  u:2 m*:1 p:1 (* robot choice)"}] = setup

    {:action, reply} = ppid |> Player.Worker.guess("m")

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 1q: #{inspect setup}\n"

    assert [display: true, status: {:guess_word, "cumulate",
             "Player socrates_test, Round 9, C-M-LATE; score=8; status=KEEP_GUESSING.\nLast word left: cumulate"}] = setup

    {:action, reply} = ppid |> Player.Worker.guess("cumulate")

    IO.puts "\nGame 1r: #{inspect reply}\n"

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    {:transit, reply} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2a: #{inspect reply}"  # transition stop

    {:begin, reply} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2b: #{inspect reply}"  # begin

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2c: #{inspect setup}"    # setup

    {:action, reply} = ppid |> Player.Worker.guess("e")

    IO.puts "\nGame 2d: #{inspect reply}"  

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2e: #{inspect setup}"    

    {:action, reply} = ppid |> Player.Worker.guess("a")

    IO.puts "\nGame 2f: #{inspect reply}"  

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2g: #{inspect setup}"

    {:action, reply} = ppid |> Player.Worker.guess("s")

    IO.puts "\nGame 2h: #{inspect reply}"  

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2i: #{inspect setup}"

    {:action, reply} = ppid |> Player.Worker.guess("r")

    IO.puts "\nGame 2j: #{inspect reply}"  

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2k: #{inspect setup}"

    assert [display: true,
            status: {:guess_letter,
             "Possible hangman words left, 10 words: [\"abigail\", \"acclaim\", \"affiant\", \"afghani\", \"agitato\", \"animato\", \"anomaly\", \"apogamy\", \"applaud\", \"avocado\"]\n\nPlayer socrates_test, Round 5, A---A--; score=4; status=KEEP_GUESSING.\n5 weighted letter choices :  i*:6 o:5 g:4 l:4 m:4 (* robot choice)"}] = setup

    {:action, reply} = ppid |> Player.Worker.guess("i")

    IO.puts "\nGame 2l: #{inspect reply}"  

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2m: #{inspect setup}"

    {:action, reply} = ppid |> Player.Worker.guess("d")

    IO.puts "\nGame 2n: #{inspect reply}"

    {:setup, setup} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2o: #{inspect setup}"

    {:action, reply} = ppid |> Player.Worker.guess("avocado")

    IO.puts "\nGame 2p: #{inspect reply}"

    assert "AVOCADO; score=6; status=GAME_WON" = reply

    {:transit, reply} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2q: #{inspect reply}"

    assert "Game Over! Average Score: 7.0, # Games: 2, Scores:  (CUMULATE: 8) (AVOCADO: 6)" = reply

    {:exit, reply} = ppid |> Player.Worker.proceed

    IO.puts "\nGame 2r: #{inspect reply}"

    assert "Game Over! Average Score: 7.0, # Games: 2, Scores:  (CUMULATE: 8) (AVOCADO: 6)" = reply

  end


end

