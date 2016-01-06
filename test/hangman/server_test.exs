defmodule Hangman.GameServer.Test do
	use ExUnit.Case, async: true

	test "0) multiple games with two players" do 

		assert {:ok, _pid} = Hangman.Supervisor.start_link()

		# Game #1: Stanley

		stanley_game_server_pid = 
			Hangman.Cache.get_server("stanley", ["factual", "backpack"])

		assert {"stanley", :game_keep_guessing, "-------; score=0; status=KEEP_GUESSING"} = 
			Hangman.GameServer.game_status(stanley_game_server_pid)

		assert {{"stanley", :correct_letter, :game_keep_guessing, "--C----",
  		"--C----; score=1; status=KEEP_GUESSING"}, []} = 
			Hangman.GameServer.guess_letter(stanley_game_server_pid, "c")

		assert {{"stanley", :correct_letter, :game_keep_guessing, "--C-U--",
		  "--C-U--; score=2; status=KEEP_GUESSING"}, []} = 
			Hangman.GameServer.guess_letter(stanley_game_server_pid, "u")

		assert {{"stanley", :correct_letter, :game_keep_guessing, "-AC-UA-",
  		"-AC-UA-; score=3; status=KEEP_GUESSING"}, []} = 
  		Hangman.GameServer.guess_letter(stanley_game_server_pid, "a")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "FAC-UA-",
  		"FAC-UA-; score=4; status=KEEP_GUESSING"}, []} =
  		Hangman.GameServer.guess_letter(stanley_game_server_pid, "f")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "FACTUA-",
  		"FACTUA-; score=5; status=KEEP_GUESSING"}, []} =
  		Hangman.GameServer.guess_letter(stanley_game_server_pid, "t")

  	assert {{"stanley", :correct_letter, :game_won, "FACTUAL", "FACTUAL; score=6; status=GAME_WON"},
 			[]} = Hangman.GameServer.guess_letter(stanley_game_server_pid, "l")

 		assert {"stanley", :game_keep_guessing, "--------; score=0; status=KEEP_GUESSING"} =
 			Hangman.GameServer.game_status(stanley_game_server_pid) 

 		assert {{"stanley", :correct_letter, :game_keep_guessing, "--C---C-",
  		"--C---C-; score=1; status=KEEP_GUESSING"}, []} = 
  		Hangman.GameServer.guess_letter(stanley_game_server_pid, "c")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "-AC--AC-",
  		"-AC--AC-; score=2; status=KEEP_GUESSING"}, []} = 
  		Hangman.GameServer.guess_letter(stanley_game_server_pid, "a")

  	assert {{"stanley", :correct_letter, :game_keep_guessing, "-ACK-ACK",
  		"-ACK-ACK; score=3; status=KEEP_GUESSING"}, []} = 
  		Hangman.GameServer.guess_letter(stanley_game_server_pid, "k")

  	assert {{"stanley", :correct_word, :game_won, "BACKPACK", "BACKPACK; score=3; status=GAME_WON"},
 			[status: :game_over, average_score: 4.5, games: 2,
  		results: [{"FACTUAL", 6}, {"BACKPACK", 3}]]} = 
  		Hangman.GameServer.guess_word(stanley_game_server_pid, "backpack") 

  	assert {"stanley", :game_reset, 'GAME_RESET'} =
  		Hangman.GameServer.game_status(stanley_game_server_pid)


  	# Game #2: Hugo

		hugo_game_server_pid = Hangman.Cache.get_server("hugo", ["heart", "lullaby"])  

		assert stanley_game_server_pid != hugo_game_server_pid

		assert {"hugo", :game_keep_guessing, "-----; score=0; status=KEEP_GUESSING"} =
			Hangman.GameServer.game_status(hugo_game_server_pid)                             

		assert {{"hugo", :correct_letter, :game_keep_guessing, "H----",
		  "H----; score=1; status=KEEP_GUESSING"}, []} = 
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "h")

		assert {{"hugo", :incorrect_letter, :game_keep_guessing, "H----",
		  "H----; score=2; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "l")

		assert {{"hugo", :incorrect_letter, :game_keep_guessing, "H----",
		  "H----; score=3; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "g")

		assert {{"hugo", :correct_letter, :game_keep_guessing, "H-A--",
		  "H-A--; score=4; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "a")

		assert {{"hugo", :correct_letter, :game_keep_guessing, "H-AR-",
		  "H-AR-; score=5; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "r")

		assert {{"hugo", :correct_word, :game_won, "HEART", "HEART; score=5; status=GAME_WON"}, []} =
			Hangman.GameServer.guess_word(hugo_game_server_pid, "heart")  

		assert {"hugo", :game_keep_guessing, "-------; score=0; status=KEEP_GUESSING"} = 
			Hangman.GameServer.game_status(hugo_game_server_pid)        

		assert {{"hugo", :correct_letter, :game_keep_guessing, "----A--",
		  "----A--; score=1; status=KEEP_GUESSING"}, []} = 
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "a")  

		assert {{"hugo", :correct_letter, :game_keep_guessing, "----A-Y",
		  "----A-Y; score=2; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "y")

		assert {{"hugo", :incorrect_letter, :game_keep_guessing, "----A-Y",
		  "----A-Y; score=3; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "s")

		assert {{"hugo", :correct_letter, :game_keep_guessing, "L-LLA-Y",
		  "L-LLA-Y; score=4; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(hugo_game_server_pid, "l")

		assert {{"hugo", :correct_word, :game_won, "LULLABY", "LULLABY; score=4; status=GAME_WON"},
		 [status: :game_over, average_score: 4.5, games: 2,
		  results: [{"HEART", 5}, {"LULLABY", 4}]]} =
		  Hangman.GameServer.guess_word(hugo_game_server_pid, "lullaby")  

		assert {"hugo", :game_reset, 'GAME_RESET'} =
			Hangman.GameServer.game_status(hugo_game_server_pid)    

		# Game #3: Stanley      

		assert ^stanley_game_server_pid = 
			Hangman.Cache.get_server("stanley", ["jovial"])         

		assert {"stanley", :secret_length, 6} = Hangman.GameServer.secret_length(stanley_game_server_pid)                     

		assert {{"stanley", :correct_letter, :game_keep_guessing, "-----L",
		  "-----L; score=1; status=KEEP_GUESSING"}, []} =
		   Hangman.GameServer.guess_letter(stanley_game_server_pid, "l")                 

		assert {{"stanley", :correct_letter, :game_keep_guessing, "----AL",
		  "----AL; score=2; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(stanley_game_server_pid, "a")

		assert {{"stanley", :correct_letter, :game_keep_guessing, "J---AL",
		  "J---AL; score=3; status=KEEP_GUESSING"}, []} =
		  Hangman.GameServer.guess_letter(stanley_game_server_pid, "j")

		assert {{"stanley", :correct_word, :game_won, "JOVIAL", "JOVIAL; score=3; status=GAME_WON"},
		 [status: :game_over, average_score: 3.0, games: 1, results: [{"JOVIAL", 3}]]} =
		 Hangman.GameServer.guess_word(stanley_game_server_pid, "jovial")


	end

'''
	test "1) testing with hangman player fsm module" do

		assert {:ok, _pid} = Hangman.Supervisor.start_link()

		# Game #1: Stanley

		stanley_game_server_pid = 
			Hangman.Cache.get_server("stanley", ["factual", "backpack"])

		{:ok, stanley_player_pid} = 
			Hangman.Player.Supervisor.start_child("stanley", stanley_game_server_pid)

		Hangman.Player.guess(stanley_player_pid, :default_strategy)

		#Hangman.Player.guess(stanley_player_pid, {:interactive, :top_five_letters})

	end

'''



'''

	test "1) guessing letters, checking letter positions and winning game" do

		assert {:ok, _pid} = Hangman.GameServer.start_link("avocado", 5)

		assert {{:correct_letter, :game_keep_guessing, "--O---O", _text}, []} = 
			Hangman.GameServer.guess_letter("o")

		assert {{:correct_letter, :game_keep_guessing, "--OC--O", _text}, []} =
			Hangman.GameServer.guess_letter("c")

		assert {{:incorrect_letter, :game_keep_guessing, _pattern, _text}, []} = 
			Hangman.GameServer.guess_letter("x")

		assert {{:correct_letter, :game_keep_guessing, "--OC-DO", _text}, []} = 
			Hangman.GameServer.guess_letter("d")

		assert {{:correct_letter, :game_keep_guessing, "--OC-DO", _text}, []} = 
			Hangman.GameServer.guess_letter("d")

		assert {{:incorrect_letter, :game_keep_guessing, _pattern, _text}, []} = 
			Hangman.GameServer.guess_letter("f")

		assert {{:correct_letter, :game_keep_guessing, "-VOC-DO", _text}, []} = 
			Hangman.GameServer.guess_letter("v")

		assert {{:correct_letter, :game_won, "AVOCADO", _text}, []} = 
			Hangman.GameServer.guess_letter("a")

		assert :ok = Hangman.GameServer.stop

	end

	test "2) guessing letters, checking letter positions and losing game" do

		assert {:ok, _pid} = Hangman.GameServer.start_link("fantastic", 5)

		assert {{:correct_letter, :game_keep_guessing, "-A--A----", _text}, []} = 
			Hangman.GameServer.guess_letter("a")

		#Test invaid input, see if the game continues on with the same score (check not penalized)
		#Hangman.GameServer.guess_letter(123)

		assert {:game_keep_guessing, "-A--A----; score=1; status=KEEP_GUESSING"} =
			Hangman.GameServer.game_status()

		assert {{:correct_letter, :game_keep_guessing, "-A--A---C", _text}, []} =
			Hangman.GameServer.guess_letter("c")

		#Hangman.GameServer.guess_word(456)

		assert {:game_keep_guessing, "-A--A---C; score=2; status=KEEP_GUESSING"} =
			Hangman.GameServer.game_status()

		assert {{:correct_letter, :game_keep_guessing, "-AN-A---C", _text}, []} =
			Hangman.GameServer.guess_letter("n") 

		assert {{:correct_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} = 
			Hangman.GameServer.guess_letter("t")	

		#Now a string of 6 incorrect guesses (the max wrong guesses is 5)
		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.GameServer.guess_letter("m")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.GameServer.guess_letter("l")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.GameServer.guess_letter("r")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} = 
			Hangman.GameServer.guess_letter("b")

		assert {{:incorrect_letter, :game_keep_guessing, "-ANTA-T-C", _text}, []} =
			Hangman.GameServer.guess_letter("h")

		#At this point we have reached our 5 incorrect guesses, this next guess better be right!
		assert {{:incorrect_letter, :game_lost, "-ANTA-T-C", 
			"-ANTA-T-C; score=25; status=GAME_LOST"}, []} =
			 Hangman.GameServer.guess_letter("k")
	
		assert Hangman.GameServer.stop() == :ok

	end

	test "3) returns correct game status" do

		{:ok, _pid} = Hangman.GameServer.start_link("avocado", 5)

		assert {:game_keep_guessing, _text} = Hangman.GameServer.game_status()

		Hangman.GameServer.guess_letter("c") 

		assert {:game_keep_guessing, _text} = Hangman.GameServer.game_status() 

		Hangman.GameServer.guess_letter("a") 

		assert {:game_keep_guessing, "A--CA--; score=2; status=KEEP_GUESSING"} =
			Hangman.GameServer.game_status()

		Hangman.GameServer.guess_word "ashcans"

		assert {:game_keep_guessing, "A--CA--; score=3; status=KEEP_GUESSING"} =
			Hangman.GameServer.game_status() 

		Hangman.GameServer.guess_letter("x") 

		assert {:game_keep_guessing, _text} = Hangman.GameServer.game_status() 

		Hangman.GameServer.guess_letter("o") 

		assert {:game_keep_guessing, "A-OCA-O; score=5; status=KEEP_GUESSING"} =
			Hangman.GameServer.game_status() 

		assert {{:correct_word, :game_won, _pattern, _text}, []} = 
			Hangman.GameServer.guess_word("avocado")

		assert {:game_reset, 'GAME_RESET'} = Hangman.GameServer.game_status 

		assert Hangman.GameServer.stop() == :ok

	end


	test "another game" do

		#Game 1
		#avocado

		{:ok, _pid} = Hangman.GameServer.start_link_link("avocado", 5)

		assert {:correct_letter, :game_keep_guessing, "A---A--", _text} =
			Hangman.GameServer.guess_letter("a")

		assert {:correct_letter, :game_keep_guessing, "A-O-A-O", _text} =
			Hangman.GameServer.guess_letter("o")

		assert {:correct_letter, :game_keep_guessing, "AVO-A-O", _text} =
			Hangman.GameServer.guess_letter("v")

		assert {:correct_letter, :game_keep_guessing, "AVO-ADO", _text} =
			Hangman.GameServer.guess_letter("d")

		assert {:correct_word, :game_won, "AVOCADO", _text} =
			Hangman.GameServer.guess_word("avocado")

		#Game 2
		#mystical
		assert Hangman.GameServer.another_game("mystical") == :ok     

		assert {:correct_letter, :game_keep_guessing, "--S-----", _text} =
			Hangman.GameServer.guess_letter("s")

		assert {:correct_letter, :game_keep_guessing, "--S---A-", _text} =
			Hangman.GameServer.guess_letter("a")

		assert {:correct_letter, :game_keep_guessing, "--ST--A-",_text} =
			Hangman.GameServer.guess_letter("t")

		assert {:correct_letter, :game_keep_guessing, "M-ST--A-",
 			"M-ST--A-; score=4; status=KEEP_GUESSING"} =
 			Hangman.GameServer.guess_letter("m")

		assert {:correct_word, :game_won, "MYSTICAL", 
			"MYSTICAL; score=4; status=GAME_WON"} =
			Hangman.GameServer.guess_word("mystical")

		#Game 3
		#lampoon
		assert Hangman.GameServer.another_game("lampoon") == :ok     

		assert {:correct_letter, :game_keep_guessing, "--M----", _text} =
			Hangman.GameServer.guess_letter("m")

		assert {:correct_letter, :game_keep_guessing, "--M-OO-", _text} =
			Hangman.GameServer.guess_letter("o")

		assert {:correct_letter, :game_keep_guessing, "--MPOO-", _text} =
			Hangman.GameServer.guess_letter("p")

		assert {:correct_word, :game_won, "LAMPOON", _text} =
			Hangman.GameServer.guess_word("lampoon")

		assert {:game_won, 3, "LAMPOON; score=3; status=GAME_WON"} =
			Hangman.GameServer.game_status()

		#Game 4
		#dexterity
		assert Hangman.GameServer.another_game("dexterity") == :ok     

		assert {:correct_letter, :game_keep_guessing, "-E--E----", _text} =
			Hangman.GameServer.guess_letter("e")

		assert {:correct_word, :game_won, "DEXTERITY", "DEXTERITY; score=1; status=GAME_WON"} =
			Hangman.GameServer.guess_word("dexterity")

		assert {:game_won, 1, "DEXTERITY; score=1; status=GAME_WON"} = 
			Hangman.GameServer.game_status()

		assert Hangman.GameServer.stop() == :ok

	end
'''

end
