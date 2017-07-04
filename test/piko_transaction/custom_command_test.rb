# frozen_string_literal: true

require "test_helper"
require "piko_transaction/custom_command.rb"

module PikoTransaction
  class CustomCommandTest < Minitest::Test
    def setup
      @done = false
      @undone = false
      @cmd = CustomCommand.new -> { @done = true }, -> { @undone = true }
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
      @cmd = CustomCommand.new -> { false }, -> { @undone = true }
      refute @cmd.do
    end

    def test_that_can_not_call_undo_after_bad_do
      @cmd = CustomCommand.new -> { false }, -> { @undone = true }
      @cmd.do
      refute @cmd.undo
    end

    def test_that_can_not_call_undo_when_error
      @cmd = CustomCommand.new -> { @done = true }, -> { false }
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

    def test_that_do_without_block_returns_true
      @cmd = CustomCommand.new
      assert @cmd.do
    end

    def test_that_undo_without_block_returns_true
      @cmd = CustomCommand.new -> { @done = true }
      @cmd.do
      assert @cmd.undo
    end

    def test_that_can_not_call_bad_do_action
      @cmd = CustomCommand.new :doo
      refute @cmd.do
    end

    def test_that_can_not_call_bad_undo_action
      @cmd = CustomCommand.new -> { @done = true }, :undoo
      @cmd.do
      refute @cmd.undo
    end

    def test_that_executing_callback_with_exception_returns_false
      @cmd = CustomCommand.new { 1 / 0 }
      refute @cmd.do
    end

    def test_that_do_command_can_be_passed_as_block
      @cmd = CustomCommand.new { @done = true }
      @cmd.do
      assert @done
    end

    def test_that_command_has_default_string_representaton
      assert_equal "[CustomCommand]", @cmd.to_s
    end

    def test_that_command_has_name
      @cmd.name :foo_bar
      assert_equal "[foo_bar]", @cmd.to_s
    end

    def test_that_it_is_possible_to_add_more_success_observers
      spy = nil
      @cmd.add_success_callback(proc { spy = :success })
      @cmd.do
      assert @done == true && spy == :success
    end

    def test_that_it_is_possible_to_add_failure_observers
      spy = nil
      @cmd = CustomCommand.new -> { false }
      @cmd.add_failure_callback(proc { spy = :failure })
      @cmd.do
      assert @done == false && spy == :failure
    end
  end
end
