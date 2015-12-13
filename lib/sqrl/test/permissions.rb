require 'set'

module SQRL
  module Test
    class Permissions
      def initialize(req, account, login_session)
        @req = req
        self.account = account
        self.login_session = login_session
        @errors = Set.new
        @transient_error = false
      end

      attr_reader :req
      attr_reader :account
      attr_reader :login_session

      attr_reader :errors
      attr_reader :transient_error

      def account=(account)
        @account = account
        @account_found = account.found?
        @unlocked = nil
      end

      def login_session=(login_session)
        @login_session = login_session
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
        session? && ids?
      end

      def enable?
        session? && ids? && unlocked?
      end

      def ident?
        return false unless login_session? && ids? && enabled?
        if req.suk && req.vuk
          unlocked?
        end
      end

      def query?
        session? && ids?
      end

      def remove?
        session? && ids? && account? && unlocked?
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

      def session?
        return true if login_session.found?

        errors << "Valid server string required"
        @transient_error = true
        false
      end

      def login_session?
        errors << "The provided server string is not tied to a login session, so I don't know which one to login to." unless login_session.login_capable?
        login_session.login_capable?
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
