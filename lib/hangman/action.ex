defmodule Hangman.Round.Action do

	alias Hangman.{Strategy, Player}

	@letter_choices 5


  # NEW CODE (w/ function builders)

  # Data retrievers

  def retrieve_human_letter_options(%Player{} = p) do
    Strategy.choose_letters(p.strategy, @letter_choices)
  end

  def retrieve_human_guess_letter(%Player{} = p, l) do
    Strategy.letter_in_most_common(p.strategy, @letter_choices, l)
  end

  def retrieve_human_last_word(%Player{} = p) do
    Strategy.last_word(p.strategy) 
  end

  def retrieve_strategic_guess(%Player{} = p) do
    Strategy.make_guess(p.strategy)
  end

  # Feedback dispatcher

  def feedback_dispatch(p, guess), do: Player.Round.guess(p, guess) 

  # Updaters

  def updater_round_and_guess(p, round, guess) do
    Player.Round.update(p, round, guess)
  end

  def updater_round_and_strategy(p, round, strategy) do
    Player.Round.update(p, round, strategy)
  end

  def updater_letter_options_text(p, choices) do
    Player.Round.augment_choices(p, choices)
  end




  # Action function maker templates

  def make_data_feedback_update_action(fn_data_retriever, 
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


  def make_struct_feedback_update_action(fn_data_retriever, 
                                         fn_feedback_dispatcher, 
                                         fn_updater) do
    fn (%Player{} = player) -> 
      {struct, data} = fn_data_retriever.(player)
      feedback = fn_feedback_dispatcher.(player, data)
      fn_updater.(player, feedback, struct)
    end
  end


  def make_data_update_action(fn_data_retriever, fn_updater) do
    fn (%Player{} = player) -> 
      data = fn_data_retriever.(player)
      fn_updater.(player, data)
    end
  end


  # Action functions


  def perform(%Player{} = p, :guess_letter, letter)
  when is_binary(letter) do

    human_letter_guess = 
      make_data_feedback_update_action(&retrieve_human_guess_letter/2,
                                       &feedback_dispatch/2, 
                                       &updater_round_and_guess/3)    
    human_letter_guess.(p, letter)
  end

  
  def perform(%Player{} = p, :guess_last_word) do

    human_last_word_guess = 
      make_data_feedback_update_action(&retrieve_human_last_word/1, 
                                       &feedback_dispatch/2, 
                                       &updater_round_and_guess/3)
    human_last_word_guess.(p, "")
  end


  def perform(%Player{} = p, :guess) do
  	
    robot_guess = 
      make_struct_feedback_update_action(&retrieve_strategic_guess/1, 
                                          &feedback_dispatch/2, 
                                          &updater_round_and_strategy/3)
    robot_guess.(p)
  end


  def perform(%Player{} = p, :choose_letters) do

    human_choose_letters = 
      make_data_update_action(&retrieve_human_letter_options/1, 
                              &updater_letter_options_text/2)
    human_choose_letters.(p)
  end



  #### ORIGINAL CODE (w/o function builders)  #####



  def perform0(%Player{} = p, :guess_letter, letter)
  when is_binary(letter) do
    
    # If user has decided to put in a letter not in the most common choices
    # get the letter that had the highest letter counts
    
  	guess = Strategy.letter_in_most_common(p.strategy, @letter_choices, letter)
    
    round_info = Player.Round.guess(p, guess)
    
		Player.Round.update(p, round_info, guess)
  end
  
  def perform0(%Player{} = p, :guess_last_word) do

    guess = Strategy.last_word(p.strategy)
    
    round_info = Player.Round.guess(p, guess)

    Player.Round.update(p, round_info, guess)
  end


  def perform0(%Player{} = p, :guess) do
  	
    {strategy, guess} = Strategy.make_guess(p.strategy)

    round_info = Player.Round.guess(p, guess)

    Player.Round.update(p, round_info, strategy)
  end
  

  def perform0(%Player{} = p, :choose_letters) do
    
    guess_prep = {_choices_code, _text} = 
      Strategy.choose_letters(p.strategy, @letter_choices)

    _round_info = nil

    Player.Round.augment_choices(p, guess_prep)
  end

end
