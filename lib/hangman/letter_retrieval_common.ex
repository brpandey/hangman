defmodule Hangman.Letter.Retrieval.Common do
  @behaviour Hangman.Letter.Retrieval.Strategy

  alias Hangman.{Letter.Strategy, Counter}

  # English letter frequency of english letters (Wikipedia)
  @eng_letter_freq      %{
    "a" => 8.167, "b" => 1.492, "c" => 2.782, "d" => 4.253, "e" => 12.702, 
    "f" => 2.228, "g" => 2.015, "h" => 6.094, "i" => 6.966, "j" => 0.153,
    "k" => 0.772, "l" => 4.025, "m" => 2.406, "n" => 6.749, "o" => 7.507,
    "p" => 1.929, "q" => 0.095, "r" => 5.987, "s" => 6.327, "t" => 9.056,
    "u" => 2.758, "v" => 0.978, "w" => 2.360, "x" => 0.150, "y" => 1.974,
    "z" => 0.074}
  
  @word_set_size  %{micro: 2, tiny: 5, small: 9, large: 550}
  


  @doc """
  Returns optimal letter

  Method implements the most `common` letter retrieval strategy with a twist.
  Gets the first letter with the highest frequency for when the 
  current possible `Hangman` word set space is > "small". 
  The twist is when we combine the `English` language letter relative 
  frequency. For the cases where the word set is less than `small`, 
  takes the letter whose frequencies are less than or equal to half 
  the possible `Hangman` word pass `size`.
  
  E.g.for size 10, the letter `counts` would need to be 5 
  or lower to be chosen. Doesn't handle tie between letters.
  """

  def optimal(%Strategy{} = strategy) do

    tally = strategy.pass.tally
    pass_size = strategy.pass.size
    
    if Counter.empty?(tally) do
      raise HangmanError, 
      "Word not in dictionary, no words left (tally is empty)"
    end
    
    cond do
      pass_size > @word_set_size.small ->
        
        [{letter1, count1}, {letter2, count2}] = Counter.most_common(tally, 2)
        
        size_1 = ( 1 + @eng_letter_freq[letter1] ) * count1
        size_2 = ( 1 + @eng_letter_freq[letter2] ) * count2
        
        if size_2 > size_1, do: letter2, else: letter1
      true ->
        # counter is the generator, pass_size/2 is filter guard
        # grab those key value pairs where value is <= 1/2 pass size

        # returns pairs list
        kv_list = 
        for {k,v} <- Counter.items(tally), v <= pass_size/2 do {k,v} end
                      
        # if no pairs in our list, remove the filter guard and run again
        kv_list = 
        if Kernel.length(kv_list) == 0 do
          for {k,v} <- Counter.items(tally) do {k,v} end
        else kv_list end
        
        # retrieve letter with highest frequency count
        tally = Counter.new(kv_list)
        [letter] = Counter.most_common_key(tally, 1)
        
        letter
    end
  end
end
