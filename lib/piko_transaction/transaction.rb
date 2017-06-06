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

    def initialize
      @commands = []
      @done = []
      yield self if block_given?
    end

    def add(command)
      logger.debug { format "Add command: %s", command.class.name }
      @commands << command
    end

    def run
      logger.info { format "Start transaction with commands: %s", @commands.count }
      return true if run_commands
      terminate_and_roll_back
    end

    def roll_back
      logger.info { format "Rolling back transaction with commands: %s", @done.count }
      undo_done_commands
    end

    private

    def terminate_and_roll_back
      logger.error { "Could not finalize transaction!" }
      undo_done_commands
      false
    end

    def run_commands
      @commands.each do |cmd|
        logger.debug { format "Do: %s", cmd.class.name }
        unless cmd.do
          logger.error { "Command execution failed" }
          return false
        end
        @done << cmd
      end
      true
    end

    def undo_done_commands
      @done.reverse.each do |cmd|
        logger.debug { format "Undo: %s", cmd.class.name }
        unless cmd.undo
          logger.fatal { "Can not undo command" }
          break
        end
      end
    end
  end
end
