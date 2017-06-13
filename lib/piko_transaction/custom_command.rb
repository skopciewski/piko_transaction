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

    def initialize(do_action = nil, undo_action = nil, &alternative_do_action)
      @name = nil
      @do_action = choose_do_action(do_action, alternative_do_action)
      @undo_action = undo_action
      @success_callbacks = []
      @failure_callbacks = []
      @done = false
    end

    def do
      execute_do_action ? call_success_callbacks : call_failure_callbacks
    end

    def undo
      execute_undo_action
    end

    def to_s
      format "[%s]", @name || "custom_cmd"
    end

    def name(value)
      @name = value.to_s
    end

    def add_success_callback(callback)
      @success_callbacks << callback if callback.respond_to?(:call)
      logger.debug { format "%s Registered success callbacks: %i", to_s, @success_callbacks.count }
    end

    def add_failure_callback(callback)
      @failure_callbacks << callback if callback.respond_to?(:call)
      logger.debug { format "%s Registered failure callbacks: %i", to_s, @failure_callbacks.count }
    end

    private

    def choose_do_action(action, alternative_action)
      action || alternative_action
    end

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

    def execute_do_action
      return terminate("Command already done") unless can_do?
      return terminate("'Do' action do not responds to :call") unless \
        callable_action?(@do_action)
      return terminate("'Do' action returns false") unless safe_call_do_action
      mark_as_done
    end

    def safe_call_do_action
      logger.info { format "%s Executing custom 'do' action", to_s }
      return safe_call_action(@do_action) unless @do_action.nil?
      logger.warn { format "%s Nothing to 'do'", to_s }
      true
    end

    def safe_call_action(action)
      action.call ? true : false
    rescue => e
      logger.fatal { format "%s %s - %s", to_s, e.class.name, e.message }
      false
    end

    def callable_action?(action)
      action.nil? || action.respond_to?(:call)
    end

    def execute_undo_action
      return terminate("Can not undo command") unless can_undo?
      return terminate("'Undo' action do not responds to :call") unless \
        callable_action?(@undo_action)
      return terminate("'Undo' action returns false") unless safe_call_undo_action
      mark_as_undone
    end

    def safe_call_undo_action
      logger.debug { format "%s Executing custom 'undo' action", to_s }
      return safe_call_action(@undo_action) unless @undo_action.nil?
      logger.warn { format "%s Nothing to 'undo'", to_s }
      true
    end

    def call_success_callbacks
      @success_callbacks.each_with_index do |callback, i|
        logger.debug { format "%s Run %i success callback", to_s, i + 1 }
        callback.call
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
