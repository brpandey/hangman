defmodule Hangman.Application do
  use Application

  @moduledoc  """
  Main `Hangman` application.  

  From `Wikipedia`

  `Hangman` is a paper and pencil guessing game for two or more players. 
  One player thinks of a word, phrase or sentence and the other tries 
  to guess it by suggesting letters or numbers, within a certain number of 
  guesses.

  The word to guess is represented by a row of dashes, representing each letter
  of the word. In most variants, proper nouns, such as names, places, and brands,
  are not allowed. 
  
  If the guessing player suggests a letter which occurs in the word, the other 
  player writes it in all its correct positions. If the suggested letter or 
  number does not occur in the word, the other player draws one element of a 
  hanged man stick figure as a tally mark.

  The player guessing the word may, at any time, attempt to guess the whole word. 
  If the word is correct, the game is over and the guesser wins. 
  
  Otherwise, the other player may choose to penalize the guesser by adding an 
  element to the diagram. On the other hand, if the other player makes enough
  incorrect guesses to allow his opponent to complete the diagram, the game is
  also over, this time with the guesser losing. However, the guesser can also 
  win by guessing all the letters or numbers that appears in the word, thereby 
  completing the word, before the diagram is completed.
  
  The game show `Wheel of Fortune` is based on `Hangman`, but with 
  the addition of a roulette-styled wheel and cash is awarded for each letter.

  NOTE: The game implementation of `Hangman` has removed the ability to guess
  the word at any time, but only at the end. No visual depiction of a man is 
  drawn, simply the word represented by a row of dashes.
  
  `Usage:
  --name (player id) --type ("human" or "robot") --random (num random secrets, max 10)
  [--secret (hangman word(s)) --baseline] [--log --display]`
  
  or
  
  `Aliase Usage: 
  -n (player id) -t ("human" or "robot") -r (num random secrets, max 10)
  [-s (hangman word(s)) -bl] [-l -d]`
  
  """

  require Logger


  @docp """
  Main `application` callback start method. Calls `Root.Supervisor`
  and Web http server.
  """

  #@callback start(term, Keyword.t) :: Supervisor.on_start
  def start(_type, args) do
    _ = Logger.debug "Starting Hangman Application, args: #{inspect args}"
    response = Hangman.Supervisor.start_link args
    Hangman.Web.start_server
    response
  end
end
