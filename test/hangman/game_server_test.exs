defmodule Hangman.Game.Server.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Game, Player}

  setup_all do
    IO.puts "Game Test"

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
      :current_player_key => nil,
      :current_game_pid => nil,
      :cases => %{
        :stanley2 => [name: "stanley", secrets: ["factual", "backpack"]],
        :hugo2 => [name: "hugo", secrets: ["heart", "lullaby"]],
        :stanley1 => [name: "stanley", secrets: ["jovial"]]
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
    
    # Retrieve game server pid given test specific params
    game_pid = Game.Pid.Cache.get_server_pid(name, secrets)

    {:ok, apid} = Player.Alert.Supervisor.start_child(name, nil)

    # Update case context params map, for current test
    map = Map.put(map, :current_game_pid, game_pid)

    # Update params map with player and round key for current test
    map = Map.put(map, :current_player_key, {name, self()})
    map = Map.put(map, :current_round_key, {name, "(game num goes here)", "(round num goes here)"})

    on_exit fn ->
      Player.Alert.Handler.stop(apid)
      IO.puts "test finished"
    end

    {:ok, params: map}
  end


  @tag case_key: :stanley2
  test "stanley - double games", context do 

    IO.puts "\n1) Starting stanley 2 games test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    round_key = context[:params] |> Map.get(:current_round_key)

    Game.Server.register(game_pid, player_key, round_key)
    
    assert %{key: ^round_key, code: :game_keep_guessing, 
             text: "-------; score=0; status=KEEP_GUESSING"} = 
      Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "--C----", text: "--C----; score=1; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "c"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "--C-U--", text: "--C-U--; score=2; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "u"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "-AC-UA-", text: "-AC-UA-; score=3; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "FAC-UA-", text: "FAC-UA-; score=4; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "f"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "FACTUA-", text: "FACTUA-; score=5; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "t"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_won, 
             pattern: "FACTUAL", text: "FACTUAL; score=6; status=GAME_WON"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "l"})

    assert %{key: ^round_key, code: :game_start} = 
      Game.Server.status(game_pid, player_key, round_key)


    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
            pattern: "--C---C-", text: "--C---C-; score=1; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "c"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
            pattern: "-AC--AC-", text: "-AC--AC-; score=2; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
            pattern: "-ACK-ACK", text: "-ACK-ACK; score=3; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "k"})

    assert %{key: ^round_key, result: :correct_word, code: :game_won, 
            pattern: "BACKPACK", text: "BACKPACK; score=3; status=GAME_WON"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_word, "backpack"}) 

    assert %{key: ^round_key, code: :games_over,
             text: "Game Over! Average Score: 4.5, # Games: 2, Scores:  (FACTUAL: 6) (BACKPACK: 3)"} =
      Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :games_reset} = 
      Game.Server.status(game_pid, player_key, round_key)

  end



  @tag case_key: :hugo2  
  test "hugo - double games", context do

    IO.puts "\n2) Starting hugo 2 games test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    round_key = context[:params] |> Map.get(:current_round_key)

    Game.Server.register(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :game_keep_guessing, 
             text: "-----; score=0; status=KEEP_GUESSING"} = 
      Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "H----", text: "H----; score=1; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "h"})

    assert %{key: ^round_key, result: :incorrect_letter, code: :game_keep_guessing, 
             pattern: "H----", text: "H----; score=2; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "l"})

    assert %{key: ^round_key, result: :incorrect_letter, code: :game_keep_guessing, 
             pattern: "H----", text: "H----; score=3; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "g"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "H-A--", text: "H-A--; score=4; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "H-AR-", text: "H-AR-; score=5; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "r"})

    assert %{key: ^round_key, result: :correct_word, code: :game_won, 
             pattern: "HEART", text: "HEART; score=5; status=GAME_WON"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_word, "heart"})  

    assert %{key: ^round_key, code: :game_start} = 
      Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "----A--", text: "----A--; score=1; status=KEEP_GUESSING"} = 
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})  

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
            pattern: "----A-Y", text: "----A-Y; score=2; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "y"})

    assert %{key: ^round_key, result: :incorrect_letter, code: :game_keep_guessing, 
            pattern: "----A-Y", text: "----A-Y; score=3; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "s"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
            pattern: "L-LLA-Y", text: "L-LLA-Y; score=4; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "l"})

    assert %{key: ^round_key, result: :correct_word, code: :game_won, 
             pattern: "LULLABY", text: "LULLABY; score=4; status=GAME_WON"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_word, "lullaby"})  

    assert %{key: ^round_key, code: :games_over, 
             text: "Game Over! Average Score: 4.5, # Games: 2, Scores:  (HEART: 5) (LULLABY: 4)"} =
      Game.Server.status(game_pid, player_key, round_key)


    assert %{key: ^round_key, code: :games_reset} = 
      Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :games_reset} = 
      Game.Server.status(game_pid, player_key, round_key)

  end


  @tag case_key: :stanley1
  test "stanley - single game", context do

    IO.puts "\n3) Starting stanley 1 game test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    round_key = context[:params] |> Map.get(:current_round_key)

    assert {^round_key, 6, _} = 
      Game.Server.register(game_pid, player_key, round_key)

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "-----L", text: "-----L; score=1; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "l"})                 

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "----AL", text: "----AL; score=2; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{key: ^round_key, result: :correct_letter, code: :game_keep_guessing, 
             pattern: "J---AL", text: "J---AL; score=3; status=KEEP_GUESSING"} =
      Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "j"})

    assert %{key: ^round_key, result: :correct_word, code: :game_won, 
             pattern: "JOVIAL", text: "JOVIAL; score=3; status=GAME_WON"} =
     Game.Server.guess(game_pid, player_key, round_key, {:guess_word, "jovial"})


    assert %{key: ^round_key, code: :games_over, 
             text: "Game Over! Average Score: 3.0, # Games: 1, Scores:  (JOVIAL: 3)"} =
      Game.Server.status(game_pid, player_key, round_key)

  end


end
