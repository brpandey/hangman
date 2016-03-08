defmodule Guess.Action do
  @moduledoc """

  Module encapsulates hangman round actions 
  and the data associated with carrying them out. 

  Uses function builder strategy to easily be
  able to add new data retrievers, and updaters

  Two sets of implementation are given. One has a
  function builder approach the other has a more boilerplate looking
  function body which is easier to read.

  Written this way for purely erudition purposes
  """

  alias Player.Round, as: Round

  @human Player.human
  @robot Player.robot

  # CODE w/ function builders

  # Data retrievers

  @spec retrieve_letter_guess(Player.t, String.t) :: Guess.t
  defp retrieve_letter_guess(%Player{} = p, l) do
    Strategy.letter_in_most_common(p.strategy, l)
  end

  @spec retrieve_last_guess(Player.t) :: Guess.t
  defp retrieve_last_guess(%Player{} = p) do
    Strategy.last_word(p.strategy) 
  end

  @spec retrieve_strategic_guess(Player.t) :: Guess.t
  defp retrieve_strategic_guess(%Player{} = p) do
    Strategy.make_guess(p.strategy)
  end



  # Updaters
  @spec updater_round_and_guess(Player.t, Player.kind, Round.t, Guess.t) :: Player.t
  defp updater_round_and_guess(p, @human, round, guess) do
    Round.update(p, round, guess)
  end


  @spec updater_round(Player.t, Player.kind, Round.t, Guess.t) :: Player.t
  defp updater_round(p, @robot, round, _guess) do
    Round.update(p, round)
  end


  # Action function maker templates
  @spec make_guess_action(
  (Player.t -> Guess.t) | (Player.t, String.t -> Guess.t), # data retrievers
  (Player.t, Player.kind, Round.t, Guess.t -> Player.t) # updater
  ) :: Player.t
  defp make_guess_action(fn_data_retriever, fn_updater) do

    # return two headed-function
    fn
      %Player{} = player, "" ->
        data = fn_data_retriever.(player)
        feedback = Round.guess(player, data)
        fn_updater.(player, player.type, feedback, data)
      %Player{} = player, letter when is_binary(letter) ->
        data = fn_data_retriever.(player, letter)
        feedback = Round.guess(player, data)
        fn_updater.(player, player.type, feedback, data)
    end

  end



  # Action functions

  @doc """
  Performs human :guess_letter action by validating the letter is in 
  the top strategy letter choices, performing game server guess, and updating
  player with round results and guess data
  """

  @spec perform(Player.t, Guess.t) :: Player.t
  def perform(%Player{} = p, {:guess_letter, letter})
  when is_binary(letter) do

    guess = make_guess_action(&retrieve_letter_guess/2, 
                              &updater_round_and_guess/4)

    guess.(p, letter)
  end

  @doc """
  Performs human :guess_last_word action by retrieving the last word from set
  of possible hangman words, performing game server guess, and updating player
  with round results and guess data
  """

  @spec perform(Player.t, Guess.directive) :: Player.t
  def perform(%Player{} = p, :guess_last_word) do

    guess = make_guess_action(&retrieve_last_guess/1, 
                              &updater_round_and_guess/4)

    guess.(p, "")
  end

  @doc """
  Performs robot :guess action by retrieving strategy determined guess, 
  performing game server guess, and updating player with round results and
  strategy data
  """

  @spec perform(Player.t, Guess.directive) :: Player.t
  def perform(%Player{} = p, :robot_guess) do

    guess = make_guess_action(&retrieve_strategic_guess/1, &updater_round/4)
    
    guess.(p, "")
  end



  #### ORIGINAL CODE (w/o function builders)  #####

  @doc """
  Performs human :guess_letter action by validating the letter is in 
  the top strategy letter choices, performing game server guess, and updating
  player with round results and guess data
  """

  @spec perform0(Player.t, Guess.t) :: Player.t
  def perform0(%Player{} = p, {:guess_letter, letter})
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

  @spec perform0(Player.t, Guess.directive) :: Player.t
  def perform0(%Player{} = p, :guess_last_word) do

    guess = Strategy.last_word(p.strategy)
    
    round_info = Round.guess(p, guess)

    Round.update(p, round_info, guess)
  end

  @doc """
  Performs :robot_guess action by retrieving strategy determined guess, 
  performing game server guess, and updating player with round results and
  strategy data
  """

  @spec perform0(Player.t, Guess.directive) :: Player.t
  def perform0(%Player{} = p, :robot_guess) do
  	
    guess = Strategy.make_guess(p.strategy)

    round_info = Round.guess(p, guess)

    Round.update(p, round_info)
  end
  

end
