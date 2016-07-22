defmodule Player.Test do
  use ExUnit.Case, async: true

#  alias Hangman.{Player}

  setup_all do
    IO.puts "Player Test"

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
      :current_player_pid => nil,
      :cases => %{
        :robot => [name: "wall_e_test", type: :robot, 
                   secrets: ["cumulate"]],
        :human => [name: "socrates_test", type: :human, 
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

    IO.puts " "

    # Retrieve game server pid given test specific params
    game_pid = Game.Pid.Cache.get_server_pid(name, secrets)

    # Get event server pid next
    {:ok, notify_pid} = Player.Events.Supervisor.start_child(false, false)

    # Retrieve player fsm pid through dynamic start

    {:ok, player_pid} = Player.Supervisor.start_child(name, type, game_pid, notify_pid)

    # Update case context params map, for current test
    map = Map.put(map, :current_player_pid, player_pid)

    on_exit fn ->
      Player.stop(player_pid)
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

    {:action, reply} = ppid |> Player.proceed

    assert "-------E; score=1; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed 

    assert "-----A-E; score=2; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed      

    assert "-----ATE; score=3; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed
    
    assert "-----ATE; score=4; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed

    assert "-----ATE; score=5; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed

    assert "----LATE; score=6; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed

    assert "C---LATE; score=7; status=KEEP_GUESSING" = reply

    {:action, reply} = ppid |> Player.proceed

    assert "C-M-LATE; score=8; status=KEEP_GUESSING" = reply

    {:stop, reply} = ppid |> Player.proceed

    assert "CUMULATE; score=8; status=GAME_WON" = reply

    {:exit, reply} = ppid |> Player.proceed

    assert "Game Over! Average Score: 8.0, # Games: 1, Scores:  (CUMULATE: 8)" = reply

    IO.puts reply

    {:exit, reply} = ppid |> Player.proceed

    IO.puts "Asserts successfully passed, #{reply}"

  end


  @tag case_key: :human
  test "synchronous human player over 2 games", context do

    # Game 3 -- HUMAN!! socrates

    IO.puts "\n3) Starting Socrates human guessing player with 2 games \n"    

    ppid = context[:params] |> Map.get(:current_player_pid)

    #:sys.trace(ppid, true)

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"      

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("e")

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("a")

    IO.puts "\nGame 1: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("t")

    IO.puts "\nGame 1: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("o")

    IO.puts "\nGame 1: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("i")

    IO.puts "\nGame 1: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("l")

    IO.puts "\nGame 1: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("c")

    IO.puts "\nGame 1: #{reply}"

    assert "Possible hangman words left, 2 words: [\"cumulate\", \"cupulate\"]\n\nPlayer socrates_test, Round 8, C---LATE; score=7; status=KEEP_GUESSING.\n3 weighted letter choices :  u:2 m*:1 p:1 (* robot choice)" = reply

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}"  

    {_code, reply} = ppid |> Player.guess("m")

    assert "Player socrates_test, Round 9, C-M-LATE; score=8; status=KEEP_GUESSING.\nLast word left: cumulate" = reply

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 1: #{reply}\n"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.guess("e")

    IO.puts "\nGame 2: #{reply}"    

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.guess("a")

    IO.puts "\nGame 2: #{reply}"    

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.guess("s")

    IO.puts "\nGame 2: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.guess("r")

    IO.puts "\nGame 2: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.guess("i")

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"  

    {_code, reply} = ppid |> Player.guess("d")

    IO.puts "\nGame 2: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"

    {_code, reply} = ppid |> Player.proceed

    IO.puts "\nGame 2: #{reply}"

  end
end

