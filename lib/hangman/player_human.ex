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

  defp setup(%Human{} = human) do
    
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
    letter_choices = Strategy.choices(strategy)
    letter_choices = augment_choices(round, letter_choices)
    
    guess = 
      case letter_choices do
        {:guess_letter, text} ->
          letter = display(human, :letters_and_capture, text)

          # Validate the letter is in the top choices, if not
          # return the optimal letter
  	      Strategy.validate(strategy, letter)

        {:guess_word, last_word, text} -> 
          display(human, :last_word, text)
          {:guess_word, last_word}
      end

    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)

    {human, guess}
  end

  #  @spec guess(t, Round.t, Strategy.t) :: result
  def guess(%Human{} = human) do
    {human, guess} = setup(human)

    round = Round.guess(human.round, guess)
    strategy = Strategy.update(human.strategy, guess)
    status = Round.status(round)
    
    human = Kernel.put_in(human.round, round)
    human = Kernel.put_in(human.strategy, strategy)
    
    {human, status}
  end
  

  defp display(%Human{} = human, :letters_and_capture, text)
  when is_binary(text) do
    case human.display do
      true -> 
        IO.puts("\n#{text}")
        choice = IO.gets("[Please input letter choice] ")
        letter = String.strip(choice)
      false -> ""
    end
  end

  defp display(%Human{} = human, :last_word, text) 
  when is_binary(text) do
    case human.display do
      true ->
        IO.puts("\n#{text}")
      false -> ""
    end
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
      id: human.id,
      display: human.display
    ]
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      human_info = Inspect.List.inspect(Human.info(t), opts)
      round_info = Inspect.List.inspect(Round.info(t), opts)
      concat ["#Player.Human<", human_info, round_info, ">"]
    end
  end

end
