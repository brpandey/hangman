defmodule Hangman.Game.Server.Stub do

  def register(_game_pid, _player_key, {{"rabbit", 1}, 1, 0}) do
    %{key: {{"rabbit", 1}, 1, 0}, code: :guessing, data: 8,
      text: "--------; score=0; status=KEEP_GUESSING"} 
  end
  
  def register(_game_pid, _player_key, {{"rabbit", 1}, 2, 0}) do
    %{key: {{"rabbit", 1}, 2, 0}, code: :guessing, data: 7,
      text: "-------; score=0; status=KEEP_GUESSING"}
  end

  def register(_game_pid, _player_key, {{"rabbit", 2}, 1, 0}) do
    %{key: {{"rabbit", 2}, 1, 0}, code: :guessing, data: 8,
      text: "--------; score=0; status=KEEP_GUESSING"} 
  end
  

  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 1}, {:guess_letter, "e"}) do
    %{key:  {{"rabbit", 1}, 1, 1}, result: :correct_letter, code: :guessing, 
      pattern: "-------E", text: "-------E; score=1; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 2}, {:guess_letter, "a"}) do
    %{key:  {{"rabbit", 1}, 1, 2}, result: :correct_letter, code: :guessing, 
      pattern: "-----A-E", text: "-----A-E; score=2; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 3}, {:guess_letter, "t"}) do
    %{key:  {{"rabbit", 1}, 1, 3}, result: :correct_letter, code: :guessing, 
      pattern: "-----ATE", text: "-----ATE; score=3; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 4}, {:guess_letter, "o"}) do
    %{key:  {{"rabbit", 1}, 1, 4}, result: :incorrect_letter, code: :guessing, 
      pattern: "-----ATE", text: "-----ATE; score=4; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 5}, {:guess_letter, "i"}) do
    %{key:  {{"rabbit", 1}, 1, 5}, result: :incorrect_letter, code: :guessing, 
      pattern: "-----ATE", text: "-----ATE; score=5; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 6}, {:guess_letter, "l"}) do
    %{key:  {{"rabbit", 1}, 1, 6}, result: :correct_letter, code: :guessing, 
      pattern: "----LATE", text: "----LATE; score=6; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 7}, {:guess_letter, "c"}) do
    %{key:  {{"rabbit", 1}, 1, 7}, result: :correct_letter, code: :guessing, 
      pattern: "C---LATE", text: "C---LATE; score=7; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 8}, {:guess_letter, "m"}) do
    %{key:  {{"rabbit", 1}, 1, 8}, result: :correct_letter, code: :guessing, 
      pattern: "C-M-LATE", text: "C-M-LATE; score=8; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 1, 9}, {:guess_word, "cumulate"}) do
    %{key:  {{"rabbit", 1}, 1, 9}, result: :correct_word, code: :won, 
      pattern: "CUMULATE", text: "CUMULATE; score=8; status=GAME_WON"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 1}, {:guess_letter, "e"}) do
    %{key:  {{"rabbit", 1}, 2, 1}, result: :incorrect_letter, code: :guessing, 
      pattern: "-------", text: "-------; score=1; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 2}, {:guess_letter, "a"}) do
    %{key:  {{"rabbit", 1}, 2, 2}, result: :correct_letter, code: :guessing, 
      pattern: "A---A--", text: "A---A--; score=2; status=KEEP_GUESSING"}
  end  
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 3}, {:guess_letter, "s"}) do
    %{key:  {{"rabbit", 1}, 2, 3}, result: :incorrect_letter, code: :guessing, 
      pattern: "A---A--", text: "A---A--; score=3; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 4}, {:guess_letter, "r"}) do
    %{key:  {{"rabbit", 1}, 2, 4}, result: :incorrect_letter, code: :guessing, 
      pattern: "A---A--", text: "A---A--; score=4; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 5}, {:guess_letter, "i"}) do
    %{key:  {{"rabbit", 1}, 2, 5}, result: :incorrect_letter, code: :guessing, 
      pattern: "A---A--", text: "A---A--; score=5; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 6}, {:guess_letter, "d"}) do
    %{key:  {{"rabbit", 1}, 2, 6}, result: :correct_letter, code: :guessing, 
      pattern: "A---AD-", text: "A---AD-; score=6; status=KEEP_GUESSING"}
  end
  
  
  def guess(_game_pid, _player_key, {{"rabbit", 1}, 2, 7}, {:guess_word, "avocado"}) do
    %{key:  {{"rabbit", 1}, 2, 7}, result: :correct_word, code: :won, 
      pattern: "AVOCADO", text: "AVOCADO; score=6; status=GAME_WON"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 2}, 1, 1}, {:guess_letter, "e"}) do
    %{key:  {{"rabbit", 2}, 1, 1}, result: :correct_letter, code: :guessing, 
      pattern: "E------E", text: "E------E; score=1; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 2}, 1, 2}, {:guess_letter, "a"}) do
    %{key:  {{"rabbit", 2}, 1, 2}, result: :incorrect_letter, code: :guessing, 
      pattern: "E------E", text: "E------E; score=2; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 2}, 1, 3}, {:guess_letter, "i"}) do
    %{key:  {{"rabbit", 2}, 1, 3}, result: :correct_letter, code: :guessing, 
      pattern: "E----I-E", text: "E----I-E; score=3; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 2}, 1, 4}, {:guess_letter, "o"}) do
    %{key:  {{"rabbit", 2}, 1, 4}, result: :incorrect_letter, code: :guessing, 
      pattern: "E----I-E", text: "E----I-E; score=4; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 2}, 1, 5}, {:guess_letter, "r"}) do
    %{key:  {{"rabbit", 2}, 1, 5}, result: :correct_letter, code: :guessing, 
      pattern: "ER---I-E", text: "ER---I-E; score=5; status=KEEP_GUESSING"}
  end
  
  def guess(_game_pid, _player_key, {{"rabbit", 2}, 1, 6}, {:guess_word, "eruptive"}) do
    %{key:  {{"rabbit", 2}, 1, 6}, result: :correct_word, code: :won, 
      pattern: "ERUPTIVE", text: "ERUPTIVE; score=5; status=GAME_WON"}
  end
  
  
  def status(_game_pid, _player_key, {{"rabbit", 1}, 1, 9}) do
    %{key: {{"rabbit", 1}, 1, 9}, code: :start} 
  end  
  
  def status(_game_pid, _player_key, {{"rabbit", 1}, 2, 7}) do
    %{key: {{"rabbit", 1}, 2, 7}, code: :finished, 
      text: "Game Over! Average Score: 7.0, # Games: 2, Scores:  (CUMULATE: 8) (AVOCADO: 6)"}
  end
    
  def status(_game_pid, _player_key, {{"rabbit", 2}, 1, 6}) do
    %{key: {{"rabbit", 2}, 1, 6}, code: :finished, 
      text: "Game Over! Average Score: 5.0, # Games: 1, Scores:  (ERUPTIVE: 5)"}
  end

end
