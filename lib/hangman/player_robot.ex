defmodule Hangman.Player.Robot do

  @moduledoc """
  Implements robot player specific functionality

  Primarily guess setup and guessing
  """

  @opaque t :: %__MODULE__{}


  alias Hangman.{Player.Robot, Round, Letter.Strategy, Game}

  defstruct type: :robot, display: false, round: nil, strategy: nil

  @spec new(String.t, atom, pid, pid) :: t
  def new(name, display, game_pid, event_pid) when is_binary(name) 
      and is_bool(display) and is_pid(game_pid) and is_pid(event_pid) do
    
    round = %Round{ id: name, pid: self(), 
                    game_pid: game_pid, event_pid: event_pid }
    
    strategy = Strategy.new(type)
    
    %Robot{display: display, round: round, strategy: strategy}
  end  

  @doc """
  Routine for `:robot` player type. Sets up new `round`, 
  performs `auto-generated` guess, returns round `status`
  """

  @spec guess(t) :: result
  def guess(%Robot{} = robot) do
    
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

    guess = Strategy.guess(strategy)
    round = Round.guess(round, guess)

    robot = Kernel.put_in(robot.round, round)
    robot = Kernel.put_in(robot.strategy, strategy)
    
    status = Round.status(round)

    {robot, status}
  end

end
