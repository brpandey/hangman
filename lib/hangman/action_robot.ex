defmodule Hangman.Action.Robot do
  @moduledoc """
  Implements robot action player specific functionality

  The `robot` action is reliant on the game strategy to automatically 
  self select the best guess.
  """

  alias Hangman.{Action.Robot, Round, Letter.Strategy, Pass}

  defstruct type: :robot, display: false, round: nil, strategy: nil

  @type t :: %__MODULE__{}


  @doc """
  Sets up round by running a reduction pass.  Informs Strategy
  of reduction pass result to be later used in the guess method.
  """

  @spec setup(t) :: tuple
  def setup(%Robot{} = robot) do

    round = robot.round
    strategy = robot.strategy
    
    # Retrieve the exclusion set, simply the list of already guessed letters
    exclusion = strategy |> Strategy.guessed
    
    # Setup game round, passing in strategy callback routine
    {round, %Pass{} = pass} = round |> Round.setup(exclusion)

    # Process the strategy against the latest reduced word set data
    # We are using the auto self-selecting mode

    strategy = strategy |> Strategy.process(:auto, pass)

    robot = Kernel.put_in(robot.round, round)
    robot = Kernel.put_in(robot.strategy, strategy)

    {robot, []}
  end

  @doc """
  Routine for `:robot` player type. Performs `auto-generated` guess, 
  returns round `status`
  """

  @spec guess(t, Guess.t) :: tuple()
  def guess(%Robot{} = robot, _data) do

    strategy = robot.strategy
    round = robot.round
    
    guess = strategy |> Strategy.guess(:auto)
    round = round |> Round.guess(guess)
    robot = Kernel.put_in(robot.round, round)
    status = Round.status(round)

    {robot, status}
  end

  # EXTRA
  # Returns player information 
  @spec info(t) :: Keyword.t
  def info(%Robot{} = robot) do        
    _info = [
      display: robot.display
    ]
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      robot_info = Inspect.List.inspect(Robot.info(t), opts)
      round_info = Inspect.List.inspect(Round.info(t.round), opts)
      concat ["#Action.Robot<", robot_info, round_info, ">"]
    end
  end



  defimpl Hangman.Player.Action, for: Robot do

    def setup(%Robot{} = player) do
      Robot.setup(player) # returns {player, []} tuple
    end
    
    def guess(%Robot{} = player, _guess) do
      Robot.guess(player, nil) # returns {player, status} tuple
    end
    
  end
  
end
