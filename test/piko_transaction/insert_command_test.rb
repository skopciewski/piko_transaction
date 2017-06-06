# frozen_string_literal: true

require "test_helper"
require "piko_transaction/insert_command.rb"

module PikoTransaction
  class InsertCommandTest < Minitest::Test
    def setup
      @document = { foo: :bar }
      @collection = Minitest::Mock.new
      @spy = :unknown
      @cmd = InsertCommand.new(@document, @collection) { |res| @spy = res }
    end

    def test_that_can_call_do
      @collection.expect :insert_document, true, [Object]
      assert @cmd.do
    end

    def test_that_can_not_call_do_twice
      @collection.expect :insert_document, true, [Object]
      @cmd.do
      refute @cmd.do
    end

    def test_that_can_not_call_undo_without_do
      refute @cmd.undo
    end

    def test_that_can_call_undo_after_do
      @collection.expect :insert_document, true, [Object]
      @collection.expect :delete_document, true, [Object]
      @cmd.do
      assert @cmd.undo
    end

    def test_that_can_not_call_undo_after_do_twice
      @collection.expect :insert_document, true, [Object]
      @collection.expect :delete_document, true, [Object]
      @cmd.do
      @cmd.undo
      refute @cmd.undo
    end

    def test_that_do_command_returns_false_when_error
      @collection.expect :insert_document, false, [Object]
      refute @cmd.do
    end

    def test_that_can_not_call_undo_after_bad_do
      @collection.expect :insert_document, false, [Object]
      @cmd.do
      refute @cmd.undo
    end

    def test_that_can_not_call_undo_when_error
      @collection.expect :insert_document, true, [Object]
      @collection.expect :delete_document, false, [Object]
      @cmd.do
      refute @cmd.undo
    end

    def test_that_block_is_not_executed_when_error
      @collection.expect :insert_document, false, [Object]
      @cmd.do
      assert_equal :unknown, @spy
    end

    def test_that_block_gives_document_id
      @collection.expect(:insert_document, true) { |_, &b| b.call(:the_id) }
      @cmd.do
      assert_equal :the_id, @spy
    end

    def test_that_undoing_command_deletes_inserted_doc
      @collection.expect(:insert_document, true) { |_, &b| b.call(:the_id) }
      @collection.expect(:delete_document, true, [:the_id])
      @cmd.do
      @cmd.undo
      assert_mock @collection
    end
  end
end
