require 'sqrl/test/account'
require 'sqrl/test/no_account'

$accounts = []

module SQRL
  module Test
    module Accounts
      extend self

      def for_ip(ip)
        find_ip(ip) || NoAccount
      end

      def for_idk(idk)
        find_idk(idk) || NoAccount
      end

      def list
        $accounts.join(';')
      end

      def create(req)
        account = Account.new(:ip => req.login_ip, :status => :known)
        $accounts << account
        account
      end

      private
      def find_ip(ip)
        $accounts.find {|s| s[:ip] == ip}
      end

      def find_idk(idk)
        $accounts.find {|s| s[:idk] == idk}
      end
    end
  end
end
