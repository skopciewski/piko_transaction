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
  class Transaction
    include Logger

    def initialize(name = nil)
      @name = name
      @commands = []
      @done = []
      yield self if block_given?
    end

    def add(command)
      @commands << command
      logger.debug do
        format "%s Added command: %s, total: %i", to_s, command.to_s, @commands.count
      end
    end

    def do
      logger.info { format "%s Start transaction with commands: %s", to_s, @commands.count }
      return true if run_commands
      terminate_and_undo
    end

    def undo
      logger.info { format "%s Rolling back transaction with commands: %s", to_s, @done.count }
      undo_done_commands
    end

    def to_s
      format "[%s]", @name || "tr"
    end

    private

    def terminate_and_undo
      logger.error { format "%s Could not finalize transaction!", to_s }
      undo_done_commands
      false
    end

    def run_commands
      @commands.each_with_index do |cmd, i|
        unless doing_command(cmd, i)
          logger.warn { format "%s Command %s failed", to_s, cmd.to_s }
          return false
        end
        @done << cmd
      end
      true
    end

    def doing_command(cmd, i)
      logger.debug { format "%s Running %i command: %s", to_s, i + 1, cmd.to_s }
      cmd.do
    end

    def undo_done_commands
      @done.each_with_index.reverse_each do |cmd, i|
        unless undoing_command(cmd, i)
          logger.fatal { format "%s Can not undo command: %s", to_s, cmd.to_s }
          break
        end
        @done.delete(cmd)
      end
    end

    def undoing_command(cmd, i)
      logger.debug { format "%s Undoing %i command: %s", to_s, i + 1, cmd.to_s }
      cmd.undo
    end
  end
end
