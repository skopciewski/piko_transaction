# frozen_string_literal: true

# Copyright (C) 2017 Szymon Kopciewski
#
# This file is part of PikoTransaction.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "piko_transaction/logger"

module PikoTransaction
  class DeleteCommand
    include Logger

    def initialize(document_id, collection, &success_action)
      @name = nil
      @document_id = document_id
      @collection = collection
      @success_action = success_action
      @success_callbacks = []
      @failure_callbacks = []
      @deleted_doc = nil
      @done = false
    end

    def do
      add_success_callback @success_action
      remove_document ? call_success_callbacks : call_failure_callbacks
    end

    def undo
      store_document
    end

    def to_s
      format "[%s]", @name || "delete_cmd"
    end

    def name(value)
      @name = value.to_s
    end

    def add_success_callback(callback)
      @success_callbacks << callback if callback.respond_to?(:call)
      logger.debug { format "%s Registered success callbacks: %s", to_s, @success_callbacks.count }
    end

    def add_failure_callback(callback)
      @failure_callbacks << callback if callback.respond_to?(:call)
      logger.debug { format "%s Registered failure callbacks: %s", to_s, @failure_callbacks.count }
    end

    private

    def terminate(msg)
      logger.warn { format "%s %s", to_s, msg }
      false
    end

    def mark_as_done
      @done = true
    end

    def mark_as_undone
      @done = false
      true
    end

    def can_do?
      !@done
    end

    def can_undo?
      @done
    end

    def remove_document
      return terminate("Command already done") unless can_do?
      return terminate("Error during deleting document") unless delete_document_from_collection
      mark_as_done
    end

    def delete_document_from_collection
      logger.info do
        format "%s Deleting document '%s' from '%s'", to_s, @document_id, @collection.to_s
      end
      @collection.find_and_delete_document(@document_id) { |doc| @deleted_doc = doc }
    end

    def store_document
      return terminate("Can not undo without do") unless can_undo?
      return terminate("Error durind restoring document") unless insert_document_into_collection
      mark_as_undone
    end

    def insert_document_into_collection
      logger.info { format "%s Restoring document %s in %s", to_s, @deleted_doc, @collection.to_s }
      @collection.insert_document(@deleted_doc)
    end

    def call_success_callbacks
      @success_callbacks.each_with_index do |callback, i|
        logger.debug { format "%s Run %i success callback with: %s", to_s, i + 1, @deleted_doc }
        callback.call(@deleted_doc)
      end
      true
    end

    def call_failure_callbacks
      @failure_callbacks.each_with_index do |callback, i|
        logger.debug { format "%s Run %i failure callback", to_s, i + 1 }
        callback.call
      end
      false
    end
  end
end
