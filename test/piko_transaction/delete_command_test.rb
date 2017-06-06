# frozen_string_literal: true

require "test_helper"
require "piko_transaction/delete_command.rb"

module PikoTransaction
  class DeleteCommandTest < Minitest::Test
    def setup
      @document_id = :the_id
      @collection = Minitest::Mock.new
      @spy = :unknown
      @cmd = DeleteCommand.new(@document_id, @collection) { |res| @spy = res }
    end

    def test_that_can_call_do
      @collection.expect :find_and_delete_document, true, [Object]
      assert @cmd.do
    end

    def test_that_can_not_call_do_twice
      @collection.expect :find_and_delete_document, true, [Object]
      @cmd.do
      refute @cmd.do
    end

    def test_that_can_not_call_undo_without_do
      refute @cmd.undo
    end

    def test_that_can_call_undo_after_do
      @collection.expect :find_and_delete_document, true, [Object]
      @collection.expect :insert_document, true, [Object]
      @cmd.do
      assert @cmd.undo
    end

    def test_that_can_not_call_undo_after_do_twice
      @collection.expect :find_and_delete_document, true, [Object]
      @collection.expect :insert_document, true, [Object]
      @cmd.do
      @cmd.undo
      refute @cmd.undo
    end

    def test_that_do_command_returns_false_when_error
      @collection.expect :find_and_delete_document, false, [Object]
      refute @cmd.do
    end

    def test_that_can_not_call_undo_after_bad_do
      @collection.expect :find_and_delete_document, false, [Object]
      @cmd.do
      refute @cmd.undo
    end

    def test_that_can_not_call_undo_when_error
      @collection.expect :find_and_delete_document, true, [Object]
      @collection.expect :insert_document, false, [Object]
      @cmd.do
      refute @cmd.undo
    end

    def test_that_block_is_not_executed_when_error
      @collection.expect :find_and_delete_document, false, [Object]
      @cmd.do
      assert_equal :unknown, @spy
    end

    def test_that_block_gives_deleted_document
      @collection.expect(:find_and_delete_document, true) { |_, &b| b.call(:the_doc) }
      @cmd.do
      assert_equal :the_doc, @spy
    end

    def test_that_undoing_command_restoring_deleted_doc
      @collection.expect(:find_and_delete_document, true) { |_, &b| b.call(:the_doc) }
      @collection.expect(:insert_document, true, [:the_doc])
      @cmd.do
      @cmd.undo
      assert_mock @collection
    end
  end
end
