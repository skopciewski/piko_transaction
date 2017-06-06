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
      @document_id = document_id
      @collection = collection
      @success_action = success_action
      @deleted_doc = nil
      @done = false
    end

    def do
      return terminate("Command already done") unless can_do?
      return terminate("Can not delete document") unless remove_document
      call_success_action
      mark_as_done
      true
    end

    def undo
      return terminate("Can not undo command") unless can_undo?
      return terminate("Can not restore document") unless store_document
      mark_as_undone
      true
    end

    private

    def terminate(msg)
      logger.warn { msg }
      false
    end

    def mark_as_done
      @done = true
    end

    def mark_as_undone
      @done = false
    end

    def can_do?
      !@done
    end

    def can_undo?
      @done
    end

    def remove_document
      logger.info { format "Doing command with %s", @document_id }
      @collection.find_and_delete_document(@document_id) { |doc| @deleted_doc = doc }
    end

    def store_document
      logger.info { format "Restoring document: %s", @deleted_doc }
      @collection.insert_document(@deleted_doc)
    end

    def call_success_action
      return unless @success_action.is_a?(Proc)
      logger.debug { format "Executting callback with: %s", @deleted_doc }
      @success_action.call(@deleted_doc)
    end
  end
end
