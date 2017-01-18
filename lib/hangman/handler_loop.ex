defmodule Hangman.Handler.Loop do
  @moduledoc """
  Module implements simple while control flow macro in the context
  of a game client handler.  Hides the details of functional loop trickery
  """

  @doc """
  While implements a simple while true loop which runs forever
  until break() is called
  """

  defmacro while(expression, do: block) do

    # Create AST
    quote do
      # Wrap list comprehension with try/catch to handle break invocations
      # for loop termination
      try do
        # Use list comprehension generator to endlessly iterate
        for _ <- Stream.cycle([:ok]) do
          # Check expression
          if unquote(expression) do
            # Inject block
            unquote(block)
          else # Issue loop termination
            break()
          end
        end
      catch
        :break -> :ok # loop termination successful
      end
    end

  end

  # When invoked breaks control flow when called within above while macro
  def break, do: throw :break
  
end

