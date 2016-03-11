defmodule CLI.Test do
  use ExUnit.Case, async: true


  setup_all do
    IO.puts "CLI Test"
    :ok
  end


  test "cli baseline option" do

    command = "-n gustav_test -t robot -bl"
    argv = String.split(command)
    CLI.main(argv)
    
    end


  test "robot single word with display option only" do

    command = "-n herbert_test -t robot -s exotic -d"
    argv = String.split(command)
    CLI.main(argv)
    
  end

  test "robot single word with display option only and random option" do

    command = "-n kirtan_test -t robot -s exotic -d -r 2"
    argv = String.split(command)
    CLI.main(argv)
    
  end

  
  test "robot single word with log option only" do

    command = "-n anastasia_test -t robot -s sleek -l"
    argv = String.split(command)
    CLI.main(argv)
    
  end

  @tag timeout: 90_000 # 90 seconds
  test "human double words" do

#    command = "-n humphrey -t human -s \"fantastic embryo\" -d -l"
#    argv = String.split(command)

    argv = ["-n", "humphrey_test", "-t", "human", "-s", "fantastic embryo", "-d", "-l"]

    IO.puts "argv is #{inspect argv}"

    CLI.main(argv)
    
  end

  @tag timeout: 180_000 # 180 seconds
  test "random words human" do
    
    command = "-n lulu_test -t human -r 4"
    argv = String.split(command)
    CLI.main(argv)

  end


  test "random words robot" do
    
    command = "-n lulu_test -t robot -r 4"
    argv = String.split(command)
    CLI.main(argv)

  end

  test "no secrets" do
    command = "-n lulu_test -t robot"
    argv = String.split(command)

    assert catch_error(CLI.main(argv)) ==
		  %HangmanError{message: "user must specify either --\"secret\" or --\"random\" option"}

  end

  test "word not in dictionary, pass size zero" do

    command = "-n barthalemu_test -t robot -s azerbaijian"
    argv = String.split(command)
    CLI.main(argv)

  end

  test "robot, word not in dictionary - exhausted all words" do

    command = "-n harrison_test -t robot -s azerbaijan"
    argv = String.split(command)
    CLI.main(argv)
   
  end


  test "human, word not in dictionary - exhausted all words" do

    command = "-n oscar_test -t human -s azerbaijan"
    argv = String.split(command)
    CLI.main(argv)
   
  end


end
