require 'set'

module SQRL
  module Test
    class Permissions
      def initialize(req, account)
        @req = req
        self.account = account
        @errors = Set.new
      end

      attr_reader :req
      attr_reader :account

      attr_reader :errors

      def account=(account)
        @account = account
        @account_found = account.found?
        @unlocked = nil
      end

      def allow?(command)
        query = command + '?'
        __send__(query) if respond_to?(query)
      end

      def allowed_commands(commands = req.commands)
        commands.select { |command|
          allow?(command)
        }
      end

      def allow_transaction?(commands = req.commands)
        commands == allowed_commands(commands)
      end

      def disable?
        ids?
      end

      def enable?
        ids? && unlocked?
      end

      def ident?
        if req.suk && req.vuk
          ids? && enabled? && unlocked?
        else
          ids? && enabled?
        end
      end

      def query?
        ids?
      end

      def remove?
        account? && ids? && unlocked?
      end

      private

      def ids?
        @ids_valid ||= req.valid?
        errors << "Identity signature not valid" unless @ids_valid
        @ids_valid
      end

      def unlocked?
        @unlocked ||= !account.locked? || req.unlocked?(account.vuk)
        errors << "Account is locked and unlock signature not valid" unless @unlocked
        @unlocked
      end

      def enabled?
        errors << "SQRL is disabled for this account" unless account.enabled?
        account.enabled?
      end

      def account?
        errors << "Account required" unless @account_found
        @account_found
      end

      def no_account?
        errors << "Account already exists" if @account_found
        !@account_found
      end

      def idk?
        errors << "IDK required" unless req.idk
        !!req.idk
      end

      def suk?
        errors << "SUK required" unless req.suk
        !!req.suk
      end

      def vuk?
        errors << "VUK required" unless req.vuk
        !!req.vuk
      end
    end
  end
end
