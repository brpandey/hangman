defmodule Action do

  @moduledoc """
  Module encapsulates `Round` guess actions 
  and the data associated with carrying them out. 

  Uses function builder strategy to easily be
  able to add new data retrievers, and updaters.

  Data retrievers are `Strategy` methods.
  Updaters are `Round` methods.

  Relies on `Strategy` and `Round` to return updated `Player`.
  """


  @human Player.human
  @robot Player.robot


  # Data retrievers

  @docp """
  Data retriever to retrieve letter guess
  """

  @spec retrieve_letter_guess(Player.t, String.t) :: Guess.t
  defp retrieve_letter_guess(%Player{} = p, l) do
    Strategy.letter_in_most_common(p.strategy, l)
  end

  @docp """
  Data retriever to retrieve last word guess
  """

  @spec retrieve_last_guess(Player.t, String.t) :: Guess.t
  defp retrieve_last_guess(%Player{} = p, _l) do
    Strategy.last_word(p.strategy) 
  end

  @docp """
  Data retriever to strategic letter guess
  """

  @spec retrieve_strategic_guess(Player.t, String.t) :: Guess.t
  defp retrieve_strategic_guess(%Player{} = p, _l) do
    Strategy.make_guess(p.strategy)
  end



  # Updaters

  @docp """
  Updater to update `Player` with round and guess data
  """

  @spec updater_round_and_guess(Player.t, Player.kind, Round.t, Guess.t) :: Player.t
  defp updater_round_and_guess(p, @human, round, guess) do
    Round.update(p, round, guess)
  end

  @docp """
  Updater to update `Player` with guess data only
  """

  @spec updater_round(Player.t, Player.kind, Round.t, Guess.t) :: Player.t
  defp updater_round(p, @robot, round, _guess) do
    Round.update(p, round)
  end


  # Guess Action function maker
  @spec make_guess_action(
  (Player.t -> Guess.t) | (Player.t, String.t -> Guess.t), # data retrievers
  (Player.t, Player.kind, Round.t, Guess.t -> Player.t) # updater
  ) :: (Player.t, String.t -> Player.t) # returned function
  defp make_guess_action(fn_data_retriever, fn_updater) do

    # return function
    fn
      %Player{} = player, letter when is_binary(letter) ->
        data = fn_data_retriever.(player, letter)
        feedback = Round.guess(player, data)
        fn_updater.(player, player.type, feedback, data)
    end

  end



  # Action functions

  @doc """
  Performs desired action
  
  Supported modes

    * `{:guess_letter, letter}` - validates the letter is in 
    the top strategy letter choices, if not choices top letter choice.
    Guesses with letter
    * `:guess_last_word` - retrieves the last word from set
    of possible hangman word
    * `:robot_guess` - retrieves strategy determined guess

  Proceeds to perform game server guess.  
  Updates player with round results and guess data
  """

  @spec perform(Player.t, mode :: Guess.t | Guess.directive) :: Player.t
  def perform(%Player{} = player, mode) do
    
    # validate we are in the right mode
    action = 
      case mode do
        {:guess_letter, letter} when is_binary(letter) -> true
        :guess_last_word -> true
        :robot_guess -> true
          _ -> raise HangmanError, "unsupported guess action"
      end
    
    if action, do: do_guess(player, mode)
  end

_ = """
  defp do_perform(%Player{} = p, {:guess_letter, letter}) do
    # If user has decided to put in a letter not in the most common choices
    # get the letter that had the highest letter counts
    
  	guess = Strategy.letter_in_most_common(p.strategy, letter)
    round_info = Round.guess(p, guess)
		Round.update(p, round_info, guess)
  end

  defp do_perform(%Player{} = p, :guess_last_word) do
    guess = Strategy.last_word(p.strategy)
    round_info = Round.guess(p, guess)
    Round.update(p, round_info, guess)
  end

  defp do_perform(%Player{} = p, :robot_guess) do
    guess = Strategy.make_guess(p.strategy)
    round_info = Round.guess(p, guess)
    Round.update(p, round_info)
  end
"""
  
  defp do_guess(%Player{} = p, {:guess_letter, letter}) do
    guess = make_guess_action(&retrieve_letter_guess/2, 
                              &updater_round_and_guess/4)
    guess.(p, letter)
  end

  defp do_guess(%Player{} = p, :guess_last_word) do
    guess = make_guess_action(&retrieve_last_guess/2, 
                              &updater_round_and_guess/4)
    guess.(p, "")
  end

  defp do_guess(%Player{} = p, :robot_guess) do
    guess = make_guess_action(&retrieve_strategic_guess/2, &updater_round/4)
    guess.(p, "")
  end
end
