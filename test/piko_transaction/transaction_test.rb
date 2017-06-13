# frozen_string_literal: true

require "test_helper"
require "piko_transaction/transaction"

module PikoTransaction
  class TestCommand
    attr_accessor :done, :undone

    def initialize
      @done = @undone = false
    end

    def do
      @done = true
    end

    def undo
      @undone = true
    end
  end

  class TestBadCommand < TestCommand
    def do
      false
    end
  end

  class TestBadUndo < TestCommand
    def undo
      false
    end
  end

  class CountCommand
    attr_accessor :done, :undone

    def initialize
      @done = @undone = 0
    end

    def do
      @done += 1
    end

    def undo
      @undone += 1
    end
  end

  class TransactionTest < Minitest::Test
    def setup
      @transaction = Transaction.new
      @cmd1 = TestCommand.new
      @cmd2 = TestCommand.new
      @ccmd = CountCommand.new
      @cmd_bad = TestBadCommand.new
      @cmd_bad_undo = TestBadUndo.new
    end

    def test_that_transaction_returns_true
      @transaction.add @cmd1
      assert_equal true, @transaction.do
    end

    def test_that_transaction_succesfully_run_first_command
      @transaction.add @cmd1
      @transaction.add @cmd2
      @transaction.do
      assert @cmd1.done && @cmd2.done
    end

    def test_that_transaction_do_not_undo_first_command
      @transaction.add @cmd1
      @transaction.add @cmd2
      @transaction.do
      refute @cmd1.undone && @cmd2.undone
    end

    def test_that_transaction_can_do_after_undo
      @transaction.add @ccmd
      @transaction.add @cmd1
      @transaction.do
      @transaction.undo
      @transaction.do
      @transaction.undo
      assert @ccmd.done == 2 && @ccmd.undone == 2
    end

    def test_that_transaction_undo_first_command_when_the_second_is_bad
      @transaction.add @cmd1
      @transaction.add @cmd_bad
      @transaction.do
      assert_equal true, @cmd1.undone
    end

    def test_that_transaction_do_not_undo_second_command_when_the_second_is_bad
      @transaction.add @cmd1
      @transaction.add @cmd_bad
      @transaction.do
      assert_equal false, @cmd_bad.undone
    end

    def test_that_transaction_do_not_run_third_command_when_the_second_is_bad
      @transaction.add @cmd1
      @transaction.add @cmd_bad
      @transaction.add @cmd2
      @transaction.do
      assert_equal false, @cmd2.done
    end

    def test_that_transaction_undo_second_command_when_the_third_is_bad
      @transaction.add @cmd1
      @transaction.add @cmd2
      @transaction.add @cmd_bad
      @transaction.do
      assert_equal true, @cmd2.undo
    end

    def test_that_transaction_return_false_with_bad_command
      @transaction.add @cmd1
      @transaction.add @cmd_bad
      assert_equal false, @transaction.do
    end

    def test_that_transaction_return_false_with_bad_command_and_bad_undo
      @transaction.add @cmd1
      @transaction.add @cmd_bad_undo
      @transaction.add @cmd_bad
      assert_equal false, @transaction.do
    end

    def test_that_transaction_do_not_undo_firts_command_when_the_second_undo_is_bad
      @transaction.add @cmd1
      @transaction.add @cmd_bad_undo
      @transaction.add @cmd_bad
      @transaction.do
      assert_equal false, @cmd1.undone
    end

    def test_that_it_is_possible_to_add_commands_through_block
      transaction = Transaction.new do |t|
        t.add @cmd1
      end
      transaction.do
      assert_equal true, @cmd1.done
    end

    def test_that_it_is_possible_to_roll_back_all_commands
      @transaction.add @cmd1
      @transaction.add @cmd2
      @transaction.do
      @transaction.undo
      assert @cmd1.undone && @cmd2.undone
    end

    def test_that_transaction_can_run_transaction
      transaction2 = Transaction.new
      transaction2.add @cmd2
      @transaction.add @cmd1
      @transaction.add transaction2
      @transaction.do
      assert @cmd1.done && @cmd2.done
    end

    def test_that_transaction_has_default_string_representation
      transaction = Transaction.new
      assert_equal "[tr]", transaction.to_s
    end

    def test_that_transaction_has_string_representation
      transaction = Transaction.new :foo_bar
      assert_equal "[foo_bar]", transaction.to_s
    end
  end
end
