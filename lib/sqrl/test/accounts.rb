require 'sqrl/test/account'
require 'sqrl/test/no_account'

$accounts = []

module SQRL
  module Test
    module Accounts
      extend self

      def for_idk(idk)
        find_idk(idk) || NoAccount
      end

      def list
        $accounts.join(';')
      end

      def create(req)
        account = Account.new(:status => :known)
        $accounts << account
        account
      end

      private
      def find_idk(idk)
        $accounts.find {|s| s[:idk] == idk}
      end
    end
  end
end
