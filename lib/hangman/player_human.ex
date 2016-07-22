defmodule Hangman.Player.Human do

  @moduledoc """
  Implements human player specific functionality

  Primarily guess setup and guessing
  and user input retrieval (later should be passed to Player
  GenServer processed to be displayed back to CLI via message passing)
  """

  alias Hangman.{Player.Human, Round, Letter.Strategy, Game, Pass}

  @opaque t :: %__MODULE__{}

  defstruct type: :human, display: false, round: nil, strategy: nil

  def setup(%Human{} = human) do
    
    round = human.round
    strategy = human.strategy

    fn_updater = fn
      %Pass{} = word_pass ->
        # Update the strategy with the round, with the latest reduced word set data
        Strategy.update(strategy, word_pass)
    end

    {mode, _} = Round.status(round)
    exclusion = Strategy.guessed(strategy)

    # Set up the game play round
    # Retrieve the reduction pass info from the engine
    {round, strategy} = Round.setup(round, exclusion, mode, fn_updater)
    
    # Retrieve top letter strategy options,
    # and then updating options with round specific information
    choices = Strategy.choices(strategy)
    choices = augment_choices(round, choices)

    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)

    {human, choices}
  end


  #  @spec guess(t, Guess.t) :: result
  def guess(%Human{} = human, guess) do

    guess = case guess do
      {:guess_letter, text} ->
        # Validate the letter is in the top choices, if not
        # return the optimal letter
  	    letter = Strategy.validate(strategy, letter)
      {:guess_word, text} -> 
        {:guess_word, last_word}
      _ -> raise "Unsupported guess type"
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

  @spec augment_choices(Round.t, Guess.option) :: Guess.option
  def augment_choices(%Round{} = round, {code, choices_text})
  when is_binary(choices_text) do
    
    {name, _, seq_no} = Round.reduce_context_key(round)

    {_, status_text} = Round.status(round)

    text = choices_text 
    |> String.replace("{name}", "#{name}")
    |> String.replace("{round_no}", "#{seq_no}")
    |> String.replace("{status}", "#{status_text}")
    
    {code, text}
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
      player_info = Inspect.List.inspect(Human.info(t), opts)
      round_info = Inspect.List.inspect(Round.info(t), opts)
      concat ["#Player.Human<", player_info, round_info, ">"]
    end
  end

end
