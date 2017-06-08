# frozen_string_literal: true

require "test_helper"
require "piko_transaction/custom_command.rb"

module PikoTransaction
  class CustomCommandTest < Minitest::Test

    def setup
      @done = false
      @undone = false
      @cmd = CustomCommand.new ->{ @done = true }, -> { @undone = true }
    end

    def test_that_can_call_do
      assert @cmd.do
    end

    def test_that_can_not_call_do_twice
      @cmd.do
      refute @cmd.do
    end

    def test_that_can_not_call_undo_without_do
      refute @cmd.undo
    end

    def test_that_can_call_undo_after_do
      @cmd.do
      assert @cmd.undo
    end

    def test_that_can_not_call_undo_after_do_twice
      @cmd.do
      @cmd.undo
      refute @cmd.undo
    end

    def test_that_do_command_returns_false_when_block_returns_false
      @cmd = CustomCommand.new ->{ false }, -> { @undone = true }
      refute @cmd.do
    end

    def test_that_can_not_call_undo_after_bad_do
      @cmd = CustomCommand.new ->{ false }, -> { @undone = true }
      @cmd.do
      refute @cmd.undo
    end

    def test_that_can_not_call_undo_when_error
      @cmd = CustomCommand.new ->{ @done = true }, -> { false }
      @cmd.do
      refute @cmd.undo
    end

    def test_that_do_block_is_executed
      @cmd.do
      assert @done && !@undone
    end

    def test_that_undo_block_is_executed
      @cmd.do
      @cmd.undo
      assert @done && @undone
    end

    def test_that_undo_without_block_returns_true
      @cmd = CustomCommand.new ->{ @done = true }
      @cmd.do
      assert @cmd.undo
    end

    def test_that_can_not_call_bad_action
      @cmd = CustomCommand.new :doo
      refute @cmd.do
    end

    def test_that_do_command_can_be_passed_as_block
      @cmd = CustomCommand.new { @done = true }
      @cmd.do
      assert @done
    end
  end
end
