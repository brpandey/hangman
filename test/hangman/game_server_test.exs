defmodule Game.Server.Test do
  use ExUnit.Case, async: true

# alias Hangman.{Game}

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

    # Update case context params map, for current test
    map = Map.put(map, :current_game_pid, game_pid)

    # Update params map with player key for current test
    map = Map.put(map, :current_player_key, {name, self()})

    on_exit fn ->
      IO.puts "test finished"
    end

    {:ok, params: map}
  end

  @tag case_key: :stanley2
  test "stanley - double games", context do 

    IO.puts "\n1) Starting stanley 2 games test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)

    Game.Server.initiate_and_length(game_pid, player_key)
    
    assert {"stanley", :game_keep_guessing, 
            "-------; score=0; status=KEEP_GUESSING"} = 
      Game.Server.status(game_pid, player_key)

    assert {{"stanley", :correct_letter, :game_keep_guessing, "--C----",
      "--C----; score=1; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "c"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "--C-U--",
      "--C-U--; score=2; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "u"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "-AC-UA-",
      "-AC-UA-; score=3; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "a"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "FAC-UA-",
      "FAC-UA-; score=4; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "f"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "FACTUA-",
      "FACTUA-; score=5; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "t"})

    assert {{"stanley", :correct_letter, :game_won, "FACTUAL", 
             "FACTUAL; score=6; status=GAME_WON"},
      []} = Game.Server.guess(game_pid, player_key, {:guess_letter, "l"})

    assert {"stanley", :game_keep_guessing, 
            "--------; score=0; status=KEEP_GUESSING"} =
      Game.Server.status(game_pid, player_key) 

    assert {{"stanley", :correct_letter, :game_keep_guessing, "--C---C-",
      "--C---C-; score=1; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "c"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "-AC--AC-",
      "-AC--AC-; score=2; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "a"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "-ACK-ACK",
      "-ACK-ACK; score=3; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "k"})

    assert {{"stanley", :correct_word, :game_won, "BACKPACK", 
             "BACKPACK; score=3; status=GAME_WON"},
      [status: :games_over, average_score: 4.5, games: 2,
      results: [{"FACTUAL", 6}, {"BACKPACK", 3}]]} = 
      Game.Server.guess(game_pid, player_key, {:guess_word, "backpack"}) 

    #assert {nil, :game_reset, 'GAME_RESET'} =
    assert {"stanley", :game_won, "BACKPACK; score=3; status=GAME_WON"} = 
      Game.Server.status(game_pid, player_key)

  end


  @tag case_key: :hugo2  
  test "hugo - double games", context do

    IO.puts "\n2) Starting hugo 2 games test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)

    Game.Server.initiate_and_length(game_pid, player_key)

    assert {"hugo", :game_keep_guessing, 
            "-----; score=0; status=KEEP_GUESSING"} =
      Game.Server.status(game_pid, player_key)                             

    assert {{"hugo", :correct_letter, :game_keep_guessing, "H----",
      "H----; score=1; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "h"})

    assert {{"hugo", :incorrect_letter, :game_keep_guessing, "H----",
      "H----; score=2; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "l"})

    assert {{"hugo", :incorrect_letter, :game_keep_guessing, "H----",
      "H----; score=3; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "g"})

    assert {{"hugo", :correct_letter, :game_keep_guessing, "H-A--",
      "H-A--; score=4; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "a"})

    assert {{"hugo", :correct_letter, :game_keep_guessing, "H-AR-",
      "H-AR-; score=5; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "r"})

    assert {{"hugo", :correct_word, :game_won, "HEART", 
             "HEART; score=5; status=GAME_WON"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_word, "heart"})  

    assert {"hugo", :game_keep_guessing, 
            "-------; score=0; status=KEEP_GUESSING"} = 
      Game.Server.status(game_pid, player_key)        

    assert {{"hugo", :correct_letter, :game_keep_guessing, "----A--",
      "----A--; score=1; status=KEEP_GUESSING"}, []} = 
      Game.Server.guess(game_pid, player_key, {:guess_letter, "a"})  

    assert {{"hugo", :correct_letter, :game_keep_guessing, "----A-Y",
      "----A-Y; score=2; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "y"})

    assert {{"hugo", :incorrect_letter, :game_keep_guessing, "----A-Y",
      "----A-Y; score=3; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "s"})

    assert {{"hugo", :correct_letter, :game_keep_guessing, "L-LLA-Y",
      "L-LLA-Y; score=4; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "l"})

    assert {{"hugo", :correct_word, :game_won, "LULLABY", 
             "LULLABY; score=4; status=GAME_WON"},
     [status: :games_over, average_score: 4.5, games: 2,
      results: [{"HEART", 5}, {"LULLABY", 4}]]} =
      Game.Server.guess(game_pid, player_key, {:guess_word, "lullaby"})  

    #assert {nil, :game_reset, 'GAME_RESET'} =
    assert {"hugo", :game_won, "LULLABY; score=4; status=GAME_WON"} = 
      Game.Server.status(game_pid, player_key)    

  end

  @tag case_key: :stanley1
  test "stanley - single game", context do

    IO.puts "\n3) Starting stanley 1 game test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)

    assert {"stanley", :secret_length, 6, _} = 
      Game.Server.initiate_and_length(game_pid, player_key)

    assert {{"stanley", :correct_letter, :game_keep_guessing, "-----L",
      "-----L; score=1; status=KEEP_GUESSING"}, []} =
       Game.Server.guess(game_pid, player_key, {:guess_letter, "l"})                 

    assert {{"stanley", :correct_letter, :game_keep_guessing, "----AL",
      "----AL; score=2; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "a"})

    assert {{"stanley", :correct_letter, :game_keep_guessing, "J---AL",
      "J---AL; score=3; status=KEEP_GUESSING"}, []} =
      Game.Server.guess(game_pid, player_key, {:guess_letter, "j"})

    assert {{"stanley", :correct_word, :game_won, "JOVIAL", 
             "JOVIAL; score=3; status=GAME_WON"},
            [status: :games_over, average_score: 3.0, games: 1, 
             results: [{"JOVIAL", 3}]]} =
     Game.Server.guess(game_pid, player_key, {:guess_word, "jovial"})


  end

end
