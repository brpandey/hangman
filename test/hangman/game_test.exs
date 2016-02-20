defmodule Hangman.Game.Test do
	use ExUnit.Case, async: true

	alias Hangman.{Game}

  setup_all do
    {:ok, _pid} = Hangman.Supervisor.start_link()

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
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
    game_pid = Game.Pid.Cache.Server.get_server_pid(name, secrets)

    # Update case context params map, for current test
    map = Map.put(map, :current_game_pid, game_pid)

    on_exit fn ->
      IO.puts "test finished"
    end

    {:ok, params: map}
  end

  @tag case_key: :stanley2
	test "stanley - double games", context do 

    IO.puts "\n1) Starting stanley 2 games test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)

		assert {"stanley", :game_keep_guessing, 
            "-------; score=0; status=KEEP_GUESSING"} = 
			Game.Server.game_status(game_pid)

		assert {{"stanley", :correct_letter, :game_keep_guessing, "--C----",
  		"--C----; score=1; status=KEEP_GUESSING"}, []} = 
			Game.Server.guess_letter(game_pid, "c")

		assert {{"stanley", :correct_letter, :game_keep_guessing, "--C-U--",
		  "--C-U--; score=2; status=KEEP_GUESSING"}, []} = 
			Game.Server.guess_letter(game_pid, "u")

		assert {{"stanley", :correct_letter, :game_keep_guessing, "-AC-UA-",
  		"-AC-UA-; score=3; status=KEEP_GUESSING"}, []} = 
  		Game.Server.guess_letter(game_pid, "a")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "FAC-UA-",
  		"FAC-UA-; score=4; status=KEEP_GUESSING"}, []} =
  		Game.Server.guess_letter(game_pid, "f")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "FACTUA-",
  		"FACTUA-; score=5; status=KEEP_GUESSING"}, []} =
  		Game.Server.guess_letter(game_pid, "t")

  	assert {{"stanley", :correct_letter, :game_won, "FACTUAL", 
             "FACTUAL; score=6; status=GAME_WON"},
 			[]} = Game.Server.guess_letter(game_pid, "l")

 		assert {"stanley", :game_keep_guessing, 
            "--------; score=0; status=KEEP_GUESSING"} =
 			Game.Server.game_status(game_pid) 

 		assert {{"stanley", :correct_letter, :game_keep_guessing, "--C---C-",
  		"--C---C-; score=1; status=KEEP_GUESSING"}, []} = 
  		Game.Server.guess_letter(game_pid, "c")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "-AC--AC-",
  		"-AC--AC-; score=2; status=KEEP_GUESSING"}, []} = 
  		Game.Server.guess_letter(game_pid, "a")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "-ACK-ACK",
  		"-ACK-ACK; score=3; status=KEEP_GUESSING"}, []} = 
  		Game.Server.guess_letter(game_pid, "k")

  	assert {{"stanley", :correct_word, :game_won, "BACKPACK", 
             "BACKPACK; score=3; status=GAME_WON"},
 			[status: :game_over, average_score: 4.5, games: 2,
  		results: [{"FACTUAL", 6}, {"BACKPACK", 3}]]} = 
  		Game.Server.guess_word(game_pid, "backpack") 

  	assert {"stanley", :game_reset, 'GAME_RESET'} =
  		Game.Server.game_status(game_pid)

  end

  @tag case_key: :hugo2  
  test "hugo - double games", context do

    IO.puts "\n2) Starting hugo 2 games test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)

		assert {"hugo", :game_keep_guessing, 
            "-----; score=0; status=KEEP_GUESSING"} =
			Game.Server.game_status(game_pid)                             

		assert {{"hugo", :correct_letter, :game_keep_guessing, "H----",
		  "H----; score=1; status=KEEP_GUESSING"}, []} = 
		  Game.Server.guess_letter(game_pid, "h")

		assert {{"hugo", :incorrect_letter, :game_keep_guessing, "H----",
		  "H----; score=2; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "l")

		assert {{"hugo", :incorrect_letter, :game_keep_guessing, "H----",
		  "H----; score=3; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "g")

		assert {{"hugo", :correct_letter, :game_keep_guessing, "H-A--",
		  "H-A--; score=4; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "a")

		assert {{"hugo", :correct_letter, :game_keep_guessing, "H-AR-",
		  "H-AR-; score=5; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "r")

		assert {{"hugo", :correct_word, :game_won, "HEART", 
             "HEART; score=5; status=GAME_WON"}, []} =
			Game.Server.guess_word(game_pid, "heart")  

		assert {"hugo", :game_keep_guessing, 
            "-------; score=0; status=KEEP_GUESSING"} = 
			Game.Server.game_status(game_pid)        

		assert {{"hugo", :correct_letter, :game_keep_guessing, "----A--",
		  "----A--; score=1; status=KEEP_GUESSING"}, []} = 
		  Game.Server.guess_letter(game_pid, "a")  

		assert {{"hugo", :correct_letter, :game_keep_guessing, "----A-Y",
		  "----A-Y; score=2; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "y")

		assert {{"hugo", :incorrect_letter, :game_keep_guessing, "----A-Y",
		  "----A-Y; score=3; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "s")

		assert {{"hugo", :correct_letter, :game_keep_guessing, "L-LLA-Y",
		  "L-LLA-Y; score=4; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "l")

		assert {{"hugo", :correct_word, :game_won, "LULLABY", 
             "LULLABY; score=4; status=GAME_WON"},
		 [status: :game_over, average_score: 4.5, games: 2,
		  results: [{"HEART", 5}, {"LULLABY", 4}]]} =
		  Game.Server.guess_word(game_pid, "lullaby")  

		assert {"hugo", :game_reset, 'GAME_RESET'} =
			Game.Server.game_status(game_pid)    

  end

  @tag case_key: :stanley1
  test "stanley - single game", context do

    IO.puts "\n3) Starting stanley 1 game test \n"

    game_pid = context[:params] |> Map.get(:current_game_pid)

		assert {"stanley", :secret_length, 6, _} = 
      Game.Server.secret_length(game_pid)                     

		assert {{"stanley", :correct_letter, :game_keep_guessing, "-----L",
		  "-----L; score=1; status=KEEP_GUESSING"}, []} =
		   Game.Server.guess_letter(game_pid, "l")                 

		assert {{"stanley", :correct_letter, :game_keep_guessing, "----AL",
		  "----AL; score=2; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "a")

		assert {{"stanley", :correct_letter, :game_keep_guessing, "J---AL",
		  "J---AL; score=3; status=KEEP_GUESSING"}, []} =
		  Game.Server.guess_letter(game_pid, "j")

		assert {{"stanley", :correct_word, :game_won, "JOVIAL", 
             "JOVIAL; score=3; status=GAME_WON"},
		        [status: :game_over, average_score: 3.0, games: 1, 
             results: [{"JOVIAL", 3}]]} =
		 Game.Server.guess_word(game_pid, "jovial")


	end


'''
	test "2) guessing letters, checking letter positions and losing game" do

		assert {:ok, _pid} = Game.Server.start_link("fantastic", 5)

		assert {{:correct_letter, :game_keep_guessing, "-A--A----", _text}, []} = 
			Game.Server.guess_letter("a")

		#Test invaid input, see if the game continues on with the same score (check not penalized)
		#Game.Server.guess_letter(123)

		assert {:game_keep_guessing, "-A--A----; score=1; status=KEEP_GUESSING"} =
			Game.Server.game_status()

		assert {{:correct_letter, :game_keep_guessing, "-A--A---C", _text}, []} =
			Game.Server.guess_letter("c")

		#Game.Server.guess_word(456)

		assert {:game_keep_guessing, "-A--A---C; score=2; status=KEEP_GUESSING"} =
			Game.Server.game_status()

		assert {{:correct_letter, :game_keep_guessing, "-AN-A---C", _text}, []} =
			Game.Server.guess_letter("n") 

		assert {{:correct_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} = 
			Game.Server.guess_letter("t")	

		#Now a string of 6 incorrect guesses (the max wrong guesses is 5)
		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Game.Server.guess_letter("m")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Game.Server.guess_letter("l")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Game.Server.guess_letter("r")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} = 
			Game.Server.guess_letter("b")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Game.Server.guess_letter("h")

		#At this point we have reached our 5 incorrect guesses, this next guess better be right!
		assert {{:incorrect_letter, :game_lost, "-ANTA-T-C", 
			"-ANTA-T-C; score=25; status=GAME_LOST"}, []} =
			 Game.Server.guess_letter("k")
	
		assert Game.Server.stop() == :ok

	end

'''

'''

	test "another game" do

		#Game 1
		#avocado

		{:ok, _pid} = Game.Server.start_link_link("avocado", 5)

		assert {:correct_letter, :game_keep_guessing, "A---A--", _text} =
			Game.Server.guess_letter("a")

		assert {:correct_letter, :game_keep_guessing, "A-O-A-O", _text} =
			Game.Server.guess_letter("o")

		assert {:correct_letter, :game_keep_guessing, "AVO-A-O", _text} =
			Game.Server.guess_letter("v")

		assert {:correct_letter, :game_keep_guessing, "AVO-ADO", _text} =
			Game.Server.guess_letter("d")

		assert {:correct_word, :game_won, "AVOCADO", _text} =
			Game.Server.guess_word("avocado")

		#Game 2
		#mystical
		assert Game.Server.another_game("mystical") == :ok     

		assert {:correct_letter, :game_keep_guessing, "--S-----", _text} =
			Game.Server.guess_letter("s")

		assert {:correct_letter, :game_keep_guessing, "--S---A-", _text} =
			Game.Server.guess_letter("a")

		assert {:correct_letter, :game_keep_guessing, "--ST--A-",_text} =
			Game.Server.guess_letter("t")

		assert {:correct_letter, :game_keep_guessing, "M-ST--A-",
 			"M-ST--A-; score=4; status=KEEP_GUESSING"} =
 			Game.Server.guess_letter("m")

		assert {:correct_word, :game_won, "MYSTICAL", 
			"MYSTICAL; score=4; status=GAME_WON"} =
			Game.Server.guess_word("mystical")

		#Game 3
		#lampoon
		assert Game.Server.another_game("lampoon") == :ok     

		assert {:correct_letter, :game_keep_guessing, "--M----", _text} =
			Game.Server.guess_letter("m")

		assert {:correct_letter, :game_keep_guessing, "--M-OO-", _text} =
			Game.Server.guess_letter("o")

		assert {:correct_letter, :game_keep_guessing, "--MPOO-", _text} =
			Game.Server.guess_letter("p")

		assert {:correct_word, :game_won, "LAMPOON", _text} =
			Game.Server.guess_word("lampoon")

		assert {:game_won, 3, "LAMPOON; score=3; status=GAME_WON"} =
			Game.Server.game_status()

		#Game 4
		#dexterity
		assert Game.Server.another_game("dexterity") == :ok     

		assert {:correct_letter, :game_keep_guessing, "-E--E----", _text} =
			Game.Server.guess_letter("e")

		assert {:correct_word, :game_won, "DEXTERITY", "DEXTERITY; score=1; status=GAME_WON"} =
			Game.Server.guess_word("dexterity")

		assert {:game_won, 1, "DEXTERITY; score=1; status=GAME_WON"} = 
			Game.Server.game_status()

		assert Game.Server.stop() == :ok

	end
'''

end
