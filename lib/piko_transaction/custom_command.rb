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
  class CustomCommand
    include Logger

    def initialize(do_action, undo_action = nil)
      @do_action = do_action
      @undo_action = undo_action
      @done = false
    end

    def do
      return terminate("Command already done") unless can_do?
      return terminate("Can not execute 'do' action") unless execute_do_action
      mark_as_done
      true
    end

    def undo
      return terminate("Can not undo command") unless can_undo?
      return terminate("Can not execute 'undo' action") unless execute_undo_action
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

    def execute_do_action
      return terminate("Can not call 'do' action") unless @do_action.respond_to? :call
      logger.debug { "Executing do action" }
      @do_action.()
    end

    def execute_undo_action
      return true unless @undo_action.respond_to? :call
      logger.debug { "Executing undo action" }
      @undo_action.()
    end
  end
end
