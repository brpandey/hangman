defmodule Hangman.Player.Robot do

  @moduledoc """
  Implements robot player specific functionality

  Primarily guess setup and guessing
  """

  @opaque t :: %__MODULE__{}


  alias Hangman.{Player.Robot, Round, Letter.Strategy, Game}

  defstruct type: :robot, display: false, round: nil, strategy: nil


  def setup(%Robot{} = robot) do

    round = robot.round
    strategy = robot.strategy

    {mode, _} = Round.status(round)
    
    fn_updater = fn
      %Pass{} = word_pass ->
        # Update the strategy with the round, with the latest reduced word set data
        Strategy.update(strategy, word_pass)
    end
    
    exclusion = Strategy.guessed(strategy)
    
    # Setup game start round
    {round, strategy} = Round.setup(round, exclusion, mode, fn_updater)
    robot = Kernel.put_in(robot.strategy, strategy)

    {robot, []}
  end

  @doc """
  Routine for `:robot` player type. Sets up new `round`, 
  performs `auto-generated` guess, returns round `status`
  """

  @spec guess(t) :: result
  def guess(%Robot{} = robot, _data) do
    
    guess = Strategy.guess(robot.strategy)
    round = Round.guess(robot.round, guess)
    robot = Kernel.put_in(robot.round, round)
    status = Round.status(round)

    {robot, status}
  end

end
