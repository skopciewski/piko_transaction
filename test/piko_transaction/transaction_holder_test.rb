# frozen_string_literal: true

require "test_helper"
require "piko_transaction/transaction_holder"

module PikoTransaction
  class TransactionHolderTest < Minitest::Test
    def setup
      @th = TransactionHolder.new
    end

    def test_that_it_gives_transaction
      assert_instance_of Transaction, @th.foo
    end

    def test_that_it_gives_same_transaction_second_time
      tr = @th.foo
      assert_same tr, @th.foo
    end

    def test_that_it_accepts_simple_names
      assert_respond_to @th, :foo
    end

    def test_that_it_do_not_accepts_othe_names
      refute_respond_to @th, "boo bar"
    end
  end
end
