defmodule Hangman.Handler.Accumulator.Test do
  use ExUnit.Case

  import Hangman.Handler.Accumulator



  test "done with no value terminates loop and no values are accumulated" do

    # send msg to self
    send self(), :one

    # wrap receive block in our repeatedly macro
    list = repeatedly do
      receive do

        :one -> # no next
          send self(), :two

        :two -> # no next
          send self(), :three

        :three -> # no next
          send self(), :four

        :four ->
          # :finished should be received outside of while macro
          send self(), :finished 

          # Issue loop termination
          done()
      end
    end

    # assert loop has terminated and we have received last msg
    assert_received :finished

    # assert we haven't accumulated anything and just have an empty list
    assert list == []
  end


  test "done with no value terminates loop and values are accumulated" do

    # send msg to self
    send self(), :one

    # wrap receive block in our repeatedly macro
    list = repeatedly do
      receive do

        :one -> # explicit next
          send self(), :two
          next(:one) # add :one to our accumulator

        :two -> # no explicit next
          send self(), :three

        :three -> # explicit next
          send self(), :four
          next(:three) # add :three to our accumulator

        :four ->
          # :finished should be received outside of while macro
          send self(), :finished 

          # Issue loop termination
          done()
      end
    end

    assert_received :finished
    assert list == [:one, :three]
  end



  test "done with value terminates loop and values are accumulated" do

    # send msg to self
    send self(), :one

    # wrap receive block in our repeatedly macro
    list = repeatedly do
      receive do

        :one -> # explicit next
          send self(), :two
          next(:one) # add :one to our accumulator

        :two -> # no explicit next
          send self(), :three

        :three -> # empty explicit next
          send self(), :four
          next()

        :four ->
          # :finished should be received outside of while macro
          send self(), :finished 

          # Issue loop termination and add :finished to our accumulator
          done(:finished)
          
      end
    end

    assert_received :finished
    assert list == [:one, :finished]
  
  end

end
