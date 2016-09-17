defmodule Hangman.Pattern.Test do
  use ExUnit.Case
  use EQC.ExUnit



  property "the union of a hangman pattern with its inverse pattern equals the original secret" do

    # Property

    # The union of the guessed hangman pattern along with the inverse guessed hangman pattern 
    # equals the original hangman secret pattern

    # We are using inverse functions to design the property

    # Create a generator for the hangman secret lengths
    # ranging from a min secret length of 3 letters to a max of 28
    forall len <- choose(3, 28) do 

      # Create a generator that produces a variable sized alphabet char list
      # we use this as the hangman secret char list
      let list <- vector(len, oneof(:lists.seq(?A, ?Z))) do

        secret = to_string(list)

        # Run the setup reduce function len times so we are confident
        # the Hangman.Pattern.update function has been run enough

        {pattern, inversed_pattern} = setup(list, secret, len)

        # sort original secret string codepoints
        sorted1 = secret |> String.codepoints |> Enum.sort

        # quick check recommends combining f's and inverse f's to recreate the original

        # combine function and inverse function values, 
        # replace the temporary hyphens with the empty character and sort codepoints
        # just like above
        sorted2 = (pattern <> inversed_pattern) 
        |> String.replace("-", "") 
        |> String.codepoints |> Enum.sort

        ensure sorted1 == sorted2

      end
    end
  end


  def setup(list, secret, n) when is_list(list) and is_binary(secret) and is_number(n) do

    # We run the reduce function a total of n times (n is typically the secret length)
    # so that we get to do the pattern updates and inversed pattern updates
    # over the size of the secret -- making them dependant on each previous
    # pass
    
    # For the initial reduce acc, we set list to list
    # the pattern is the initally empty string of hyphens
    # the inversed pattern is the secret
    
    # At the end the inversed pattern will be mostly checkered with "-"
    # and the pattern should checkered with most of the letters
    # this is not guarenteed since the random function will produce
    # the same letter over len # attempts
    
    # The union of these two will give the perfect contents of the original secret
    # since they are mutually exclusive
    
    # For example given the secret string "NFZULCCW"
    # Since the len is 8, we run the reduce 8 times
    # The pattern could at this point look like
    # "NF-ULCCW" initially from "--------" and the 
    # inverse pattern "--Z-----"
    
    # The codepoints sorted equal the following list
    # [<<"C">>,<<"C">>,<<"F">>,<<"L">>,<<"N">>,<<"U">>,<<"W">>,<<"Z">>],
    
    # Here's another example after 8 rounds:
    # secret: <<"HRZZEION">>
    # pattern: <<"--ZZE-O-">>
    # inverse pattern: <<"HR---I-N">>
    # sorted list for secret: [<<"E">>,<<"H">>,<<"I">>,<<"N">>,<<"O">>,<<"R">>,<<"Z">>,<<"Z">>],
    # sorted list for pattern + inverse - hypens: 
    # [<<"E">>,<<"H">>,<<"I">>,<<"N">>,<<"O">>,<<"R">>,<<"Z">>,<<"Z">>]
    
    # They're the same sorted list
    
    
    pattern = String.duplicate("-", String.length(secret))
    
    result = Enum.reduce(1..n, {list, secret, pattern, secret}, fn _i, acc ->
      
      {list, secret, pattern, inversed_pattern} = acc
      
      letter = get_letter(list)
      
      pattern = pattern |> pattern_update(secret, letter)
      inversed_pattern = inversed_pattern |> pattern_inverse_update(letter)
      
      {list, secret, pattern, inversed_pattern}
      
    end)
    
    {^list, ^secret, pattern, inversed_pattern} = result
    
    {pattern, inversed_pattern}
  end

  # convenience routine
  def get_letter(list) do
    letter = list |> Enum.random 
    to_string([letter])
  end

  # original function we want to test
  def pattern_update(pattern, secret, letter) do
    Hangman.Pattern.update(pattern, secret, letter)    
  end

  # inverse of original function
  def pattern_inverse_update(pattern, letter) do
    String.replace(pattern, letter, "-")
  end


end
