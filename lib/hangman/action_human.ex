defmodule Hangman.Action.Human do
  @moduledoc """
  Implements human action player specific functionality

  In `Hangman` we have two players.  One explict - the one guessing, the other
  implicit, 'the game', 'the user tracking the penalties'.  

  In this instance, the `Action` is
  merely the user making and choosing the guess selections.  

  The `human` action is given the choice of the top letter choices to choose
  from and is able to make an interactive guess.  
  """

  alias Hangman.{Action.Human, Round, Letter.Strategy, Pass}

  defstruct type: :human, display: false, round: nil, strategy: nil

  @type t :: %__MODULE__{}

  @doc """
  Sets up round by running a reduction pass.  Returns
  top letter choices to be presented to human
  """

  @spec setup(t) :: tuple
  def setup(%Human{} = human) do
    round = human.round
    strategy = human.strategy

    # Retrieve the exclusion set, simply the list of already guessed letters
    exclusion = strategy |> Strategy.guessed()

    # Set up the game play round passing in letters already guessed
    # Retrieve the reduction pass info from the engine

    {round, %Pass{} = pass} = round |> Round.setup(exclusion)

    # Process the strategy against the latest reduced word set pass data
    strategy = strategy |> Strategy.process(:choices, pass)

    # Retrieve top letter strategy options augmented by round data
    choices = strategy |> Strategy.choices(round)

    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)

    {human, choices}
  end

  @doc """
  Routine for `:human` player type. Performs validation of
  human guess, executes guess and returns round `status`
  """

  @spec guess(t, Guess.t()) :: tuple | no_return
  def guess(%Human{} = human, guess) when is_tuple(guess) do
    round = human.round
    strategy = human.strategy

    # Validate the guess retrieved from the choices options
    guess = strategy |> Strategy.guess(:choices, guess)

    # Make the guess
    round = round |> Round.guess(guess)

    # Record the guess
    strategy = strategy |> Strategy.update(guess)

    # Retrieve the result
    status = round |> Round.status()

    # Store into struct
    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)

    {human, status}
  end

  # EXTRA
  # Returns player information 
  @spec info(t) :: Keyword.t()
  def info(%Human{} = human) do
    _info = [
      display: human.display
    ]
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      human_info = Inspect.List.inspect(Human.info(t), opts)
      round_info = Inspect.List.inspect(Round.info(t.round), opts)
      concat(["#Action.Human<", human_info, round_info, ">"])
    end
  end

  defimpl Hangman.Player.Action, for: Human do
    def setup(%Human{} = player) do
      # returns {player, choices}
      # where choices is {:guess_letter, "choices_text"} 
      # or {:guess_word, last, "text"}
      Human.setup(player)
    end

    def guess(%Human{} = player, guess) do
      # returns {player, status} tuple
      Human.guess(player, guess)
    end
  end
end
