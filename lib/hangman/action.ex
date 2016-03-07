defmodule Hangman.Round.Action do
  @moduledoc """

  Module encapsulates hangman round actions and the data associated 
  with carrying them out. 

  Uses function builder strategy to easily be
  able to add new data retrievers, feedback dispatchers, and updaters

  Two sets of implementation are given. One has a
  function builder approach the other has a more boilerplate looking
  function body which is easier to read.

  Written this way for purely erudition purposes
  """

	alias Hangman.{Strategy, Player, Player.Round, Guess}


  # CODE w/ function builders

  # Data retrievers

  @spec retrieve_guess_letter(Player.t, String.t) :: Guess.t
  defp retrieve_guess_letter(%Player{} = p, l) do
    Strategy.letter_in_most_common(p.strategy, l)
  end

  @spec retrieve_last_word(Player.t) :: Guess.t
  defp retrieve_last_word(%Player{} = p) do
    Strategy.last_word(p.strategy) 
  end

  @spec retrieve_strategic_guess(Player.t) :: Strategy.result
  defp retrieve_strategic_guess(%Player{} = p) do
    Strategy.make_guess(p.strategy)
  end





  # Feedback dispatcher
  @spec feedback_dispatch(Player.t, Guess.t) :: Round.t
  defp feedback_dispatch(p, guess), do: Round.guess(p, guess) 




  # Updaters
  @spec updater_round_and_guess(Player.t, Round.t, Guess.t) :: Player.t
  defp updater_round_and_guess(p, round, guess) do
    Round.update(p, round, guess)
  end

  @spec updater_round_and_strategy(Player.t, Round.t, Strategy.t) :: Player.t
  defp updater_round_and_strategy(p, round, strategy) do
    Round.update(p, round, strategy)
  end



  # Action function maker templates
  @spec make_data_feedback_update_action(
  (Player.t -> Guess.t) | (Player.t, String.t -> Guess.t),
  (Player.t, Guess.t -> Round.t),
  (Player.t, Round.t, Guess.t -> Player.t)
  ) :: Player.t
  defp make_data_feedback_update_action(fn_data_retriever, 
                                       fn_feedback_dispatcher, 
                                       fn_updater) do

    fn (%Player{} = player, letter) -> 
      data = 
        case letter do
          "" -> fn_data_retriever.(player)
          letter when is_binary(letter) -> 
            fn_data_retriever.(player, letter)
        end

      feedback = fn_feedback_dispatcher.(player, data)
      fn_updater.(player, feedback, data)
    end

  end

  @spec make_struct_feedback_update_action(
  (Player.t -> Strategy.result),
  (Player.t, Guess.t -> Round.t),
  (Player.t, Round.t, Strategy.t -> Player.t)
  ) :: Player.t
  defp make_struct_feedback_update_action(fn_data_retriever, 
                                         fn_feedback_dispatcher, 
                                         fn_updater) do
    fn (%Player{} = player) -> 
      {struct, data} = fn_data_retriever.(player)
      feedback = fn_feedback_dispatcher.(player, data)
      fn_updater.(player, feedback, struct)
    end
  end


  # Action functions

  @doc """
  Performs human :guess_letter action by validating the letter is in 
  the top strategy letter choices, performing game server guess, and updating
  player with round results and guess data
  """

  @spec perform0(Player.t, Guess.t) :: Player.t
  def perform0(%Player{} = p, {:guess_letter, letter})
  when is_binary(letter) do

    human_letter_guess = 
      make_data_feedback_update_action(&retrieve_guess_letter/2,
                                       &feedback_dispatch/2, 
                                       &updater_round_and_guess/3)    
    human_letter_guess.(p, letter)
  end

  @doc """
  Performs human :guess_last_word action by retrieving the last word from set
  of possible hangman words, performing game server guess, and updating player
  with round results and guess data
  """

  @spec perform0(Player.t, Guess.directive) :: Player.t
  def perform0(%Player{} = p, :guess_last_word) do

    human_last_word_guess = 
      make_data_feedback_update_action(&retrieve_last_word/1, 
                                       &feedback_dispatch/2, 
                                       &updater_round_and_guess/3)
    human_last_word_guess.(p, "")
  end

  @doc """
  Performs robot :guess action by retrieving strategy determined guess, 
  performing game server guess, and updating player with round results and
  strategy data
  """

  @spec perform0(Player.t, Guess.directive) :: Player.t
  def perform0(%Player{} = p, :robot_guess) do
  	
    robot_guess = 
      make_struct_feedback_update_action(&retrieve_strategic_guess/1, 
                                          &feedback_dispatch/2, 
                                          &updater_round_and_strategy/3)
    robot_guess.(p)
  end



  #### ORIGINAL CODE (w/o function builders)  #####

  @doc """
  Performs human :guess_letter action by validating the letter is in 
  the top strategy letter choices, performing game server guess, and updating
  player with round results and guess data
  """

  @spec perform(Player.t, Guess.t) :: Player.t
  def perform(%Player{} = p, {:guess_letter, letter})
  when is_binary(letter) do
    
    # If user has decided to put in a letter not in the most common choices
    # get the letter that had the highest letter counts
    
  	guess = Strategy.letter_in_most_common(p.strategy, letter)
    
    round_info = Round.guess(p, guess)
    
		Round.update(p, round_info, guess)
  end

  @doc """
  Performs human :guess_last_word action by retrieving the last word from set
  of possible hangman words, performing game server guess, and updating player
  with round results and guess data
  """  

  @spec perform(Player.t, Guess.directive) :: Player.t
  def perform(%Player{} = p, :guess_last_word) do

    guess = Strategy.last_word(p.strategy)
    
    round_info = Round.guess(p, guess)

    Round.update(p, round_info, guess)
  end

  @doc """
  Performs :robot_guess action by retrieving strategy determined guess, 
  performing game server guess, and updating player with round results and
  strategy data
  """

  @spec perform(Player.t, Guess.directive) :: Player.t
  def perform(%Player{} = p, :robot_guess) do
  	
    {strategy, guess} = Strategy.make_guess(p.strategy)

    round_info = Round.guess(p, guess)

    Round.update(p, round_info, strategy)
  end
  

end
