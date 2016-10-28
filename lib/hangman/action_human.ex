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

    fn_updater = fn
      %Pass{} = word_pass ->
        # Update the strategy with the round, with the latest reduced word set data
        Strategy.update(strategy, word_pass)
    end

    exclusion = Strategy.guessed(strategy)

    # Set up the game play round
    # Retrieve the reduction pass info from the engine

    {round, strategy} = Round.setup(round, exclusion, fn_updater)
    
    # Retrieve top letter strategy options,
    # and then updating options with round specific information
    choices = Strategy.choices(strategy)
    choices = update_choices(round, choices)

    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)

    {human, choices}
  end

  @doc """
  Routine for `:human` player type. Performs validation of
  human guess, executes guess and returns round `status`
  """

  @spec guess(t, Guess.t) :: tuple | no_return
  def guess(%Human{} = human, guess) when is_tuple(guess) do

    guess = 
      case guess do
        {:guess_letter, letter} ->
          # Validate the letter is in the top choices, if not
          # return the optimal letter
          Strategy.validate(human.strategy, letter)
        {:guess_word, last_word} -> {:guess_word, last_word}
        _ -> raise HangmanError, "Unsupported guess type"
      end
    
    round = Round.guess(human.round, guess)
    strategy = Strategy.update(human.strategy, guess)
    status = Round.status(round)

    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)
    
    {human, status}
  end
  

  @doc """
  Interjects specific parameters into `choices text`.
  """

  @spec update_choices(Round.t, Guess.options) :: Guess.options
  def update_choices(%Round{} = round, {:guess_letter, choices_text})
  when is_binary(choices_text) do
    text = do_update_choices(round, choices_text)
    {:guess_letter, text}
  end

  def update_choices(%Round{} = round, {:guess_word, last, choices_text})
  when is_binary(choices_text) do
    text = do_update_choices(round, choices_text)
    {:guess_word, last, text}
  end

  @spec do_update_choices(Round.t, String.t) :: String.t
  defp do_update_choices(%Round{} = round, text) when is_binary(text) do
    {name, _, round_no} = Round.round_key(round)
    {_, status_text} = Round.status(round)

    text 
    |> String.replace("{name}", "#{name}")
    |> String.replace("{round_no}", "#{round_no}")
    |> String.replace("{status}", "#{status_text}")

  end


  # EXTRA
  # Returns player information 
  @spec info(t) :: Keyword.t
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
      concat ["#Action.Human<", human_info, round_info, ">"]
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
      Human.guess(player, guess) # returns {player, status} tuple
    end
    
  end


end
