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
  class Command
    include Logger

    def initialize()
      @name = nil
      @success_callbacks = []
      @failure_callbacks = []
      @done = false
    end

    def to_s
      format "[%s]", @name || self.class.name.split("::").last
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

    def call_failure_callbacks
      @failure_callbacks.each_with_index do |callback, i|
        logger.debug { format "%s Run %i failure callback", to_s, i + 1 }
        callback.call
      end
      false
    end
  end
end
