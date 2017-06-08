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
require "piko_transaction/transaction"

module PikoTransaction
  class TransactionHolder
    include Logger

    def initialize
      @transactions = {}
    end

    def method_missing(method_name, *args, &block)
      logger.debug { format "Looking for transaction '%s'", method_name }
      return super unless valid_method_name?(method_name)
      @transactions[method_name] ||= Transaction.new
    end

    private

    def respond_to_missing?(method_name, include_private = false)
      return true if valid_method_name?(method_name)
      super
    end

    def valid_method_name?(name)
      /^\w+$/.match? name
    end
  end
end
