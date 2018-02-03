defmodule Hangman.CLI.Test do
  use ExUnit.Case, async: true

  alias Hangman.{CLI}

  setup_all do
    IO.puts("CLI Test")
    :ok
  end

  test "cli baseline option even with random specified" do
    command = "-n gustav_test -t robot -b -r 2"
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

  test "robot double word with log option only" do
    argv = ["-n", "anastasia_test", "-t", "robot", "-s", "sleek macaroon", "-l"]
    CLI.main(argv)
  end

  #  @tag timeout: :infinity
  test "parallel test with 40 random words nearly 1/2 time of sequential" do
    command = "-n p_mario_test1 -p -r 40"
    argv = String.split(command)
    CLI.main(argv)
  end

  #  @tag timeout: :infinity
  test "sequential test with 40 random words nearly double time of parallel" do
    command = "-n p_mario_test1 -t robot -r 40"
    argv = String.split(command)
    CLI.main(argv)
  end

  # Parallel Tests

  # note the parallel tests with the baseline words or small secrets list won't show much improvement
  # over sequential processing -- needs to be a bigger amount - 40 secrets or more

  # commenting out

  _ = """

    test "parallel test with baseline words" do

      command = "-n p_mario_test2 -p -b"
      argv = String.split(command)
      CLI.main(argv)
      
    end


    test "parallel test with secrets list" do

      argv = ["-n", "p_mario_test3", "--parallel", "-s", "fantastic embryo enzyme gigantic entail frolic zygote"]

      IO.puts "argv is {inspect argv}"

      CLI.main(argv)
      
    end

    test "sequential test with secrets list" do

      argv = ["-n", "p_mario_test3", "-t", "robot", "-s", "fantastic embryo enzyme gigantic entail frolic zygote"]

      IO.puts "argv is {inspect argv}"

      CLI.main(argv)
      
    end

    
    test "parallel test with secrets list with 1 word not in dictionary" do

      argv = ["-n", "p_mario_test4", "-p", "-s", "fantastic embryo enzyme azerbaijan entail frolic zygote"]

      IO.puts "argv is {inspect argv}"

      CLI.main(argv)
      
    end

  """

  test "human double words" do
    #    command = "-n humphrey -t human -s \"fantastic embryo\" -d -l"
    #    argv = String.split(command)

    argv = [
      "-n",
      "humphrey_test",
      "-t",
      "robot",
      "-s",
      "fantastic embryo",
      "-l",
      "-d",
      "-ti",
      "10"
    ]

    IO.puts("argv is #{inspect(argv)}")

    CLI.main(argv)
  end

  # 180 seconds
  @tag timeout: 180_000
  test "random words human" do
    command = "-n lulu_test1 -t human -r 4 -d -w 0"
    argv = String.split(command)
    CLI.main(argv)
  end

  test "random words robot" do
    command = "-n lulu_test2 -t robot -r 4"
    argv = String.split(command)
    CLI.main(argv)
  end

  test "no secrets" do
    command = "-n lulu_test -t robot"
    argv = String.split(command)

    assert catch_error(CLI.main(argv)) ==
             %HangmanError{
               message:
                 "user must specify either --\"secret\" --\"random\" or --\"baseline\" option"
             }
  end

  test "word not in dictionary, pass size zero" do
    argv = ["-n", "barthalemu_test1", "-t", "robot", "-s", "azerbaijan masterful", "-d", "-l"]

    CLI.main(argv)
  end

  test "word not in dictionary, pass size zero -- rearranged order of secrets" do
    argv = ["-n", "barthalemu_test2", "-t", "robot", "-s", "masterful azerbaijan", "-d", "-l"]

    CLI.main(argv)
  end

  # ERRORS!!
  # get player controller error, can't find pid sometimes -- race condition
  test "robot, word not in dictionary - exhausted all words" do
    command = "-n harrison_test -t robot -s azerbaijan -d"
    argv = String.split(command)
    CLI.main(argv)
  end

  test "human, word not in dictionary - exhausted all words" do
    command = "-n oscar_test -t human -s azerbaijan -d -w 0"
    argv = String.split(command)
    CLI.main(argv)
  end
end
