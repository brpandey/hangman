defmodule Hangman.Pattern do
  @moduledoc """
  Module handles `Hangman` pattern updates given guessed `letter`.

  Given an initial starting state of `-------` and given a letter `a`, 
  it will update the pattern to `a---a--`, for the secret 'avocado'. 

  After letters `o`, and `d`, we are two letters shy of `avocado`.

  ## Example
      iex> p = Pattern.update "-------", "avocado",  "a"
      "a---a--"

      iex> p = Pattern.update p, "avocado",  "o"        
      "a-o-a-o"

      iex> p = Pattern.update p, "avocado",  "d"
      "a-o-ado"

  """

  @doc """
  Tail recursive function, returns `pattern` string after update
  """

  @spec update(String.t(), String.t(), String.t()) :: String.t() | no_return
  def update(pattern, secret, letter) do
    do_update(String.codepoints(pattern), String.codepoints(secret), letter, [])
  end

  # Base case, first is when secret codepoints list is finished
  @spec do_update([] | [...], [] | [...], String.t(), term) :: String.t() | no_return
  defp do_update(_, [], _, value), do: List.to_string(value)

  # Base case, second is error condition, pattern can't be longer than secret
  defp do_update([], _, _, _), do: raise(HangmanError, "pattern can't be longer than secret")

  # Match only if head of secret is the desired letter
  defp do_update([_ | p_tail], [letter | s_tail], letter, value) do
    do_update(p_tail, s_tail, letter, [value | letter])
  end

  # Clause indicating letter not in the secret head, so concat existing pattern character
  defp do_update([p_head | p_tail], [_ | s_tail], letter, value) do
    do_update(p_tail, s_tail, letter, [value | p_head])
  end
end
