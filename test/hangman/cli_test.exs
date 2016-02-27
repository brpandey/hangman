defmodule Hangman.CLI.Test do
  use ExUnit.Case, async: true

  setup_all do
    IO.puts "Hangman.CLI.Test"
    :ok
  end


  test "cli baseline option" do

    command = "-n lulu -t robot -bl"
    argv = String.split(command)
    Hangman.CLI.main(argv)
    
    end


  test "robot single word with display option only" do

    command = "-n lulu -t robot -s exotic -d"
    argv = String.split(command)
    Hangman.CLI.main(argv)
    
  end

  test "robot single word with display option only and random option" do

    command = "-n lulu -t robot -s exotic -d -r 2"
    argv = String.split(command)
    Hangman.CLI.main(argv)
    
  end

  
  test "robot single word with log option only" do

    command = "-n lulu -t robot -s sleek -l"
    argv = String.split(command)
    Hangman.CLI.main(argv)
    
  end

  @tag timeout: 90_000 # 90 seconds
  test "human double words" do

#    command = "-n humphrey -t human -s \"fantastic embryo\" -d -l"
#    argv = String.split(command)

    argv = ["-n", "humphrey", "-t", "human", "-s", "fantastic embryo", "-d", "-l"]

    IO.puts "argv is #{inspect argv}"

    Hangman.CLI.main(argv)
    
  end

  @tag timeout: 180_000 # 180 seconds
  test "random words human" do
    
    command = "-n lulu -t human -r 4"
    argv = String.split(command)
    Hangman.CLI.main(argv)

  end


  test "random words robot" do
    
    command = "-n lulu -t robot -r 4"
    argv = String.split(command)
    Hangman.CLI.main(argv)

  end

  test "no secrets" do
    command = "-n lulu -t robot"
    argv = String.split(command)

    assert catch_error(Hangman.CLI.main(argv)) ==
		  %Hangman.Error{message: "user must specify either --\"secret\" or --\"random\" option"}

  end

end
