defmodule Hangman.Handler.Loop.Test do
  use ExUnit.Case

  import Hangman.Handler.Loop

  test "while loops as long as expression is truthy" do
    {:ok, pid} = Agent.start(fn -> %{data: "waka waka"} end)

    # send msg to self
    send(self(), :one)

    # wrap receive block in our while macro
    while Process.alive?(pid) do
      receive do
        :one ->
          send(self(), :two)

        :two ->
          send(self(), :three)

        :three ->
          Process.exit(pid, :kill)

          # :finished should be received outside of while macro
          # since the while expression is no longer true now
          send(self(), :finished)
      end
    end

    assert_received :finished
  end

  test "break terminates loop execution" do
    # send msg to self
    send(self(), :one)

    # wrap receive block in our while macro
    while true do
      receive do
        :one ->
          send(self(), :two)

        :two ->
          send(self(), :three)

        :three ->
          # :finished should be received outside of while macro
          send(self(), :finished)

          # Issue loop termination
          break()
      end
    end

    assert_received :finished
  end
end
