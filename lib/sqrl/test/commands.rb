module SQRL
  module Test
    class Commands
      def initialize(req, account, login_session)
        @req = req
        @account = account
        @login_session = login_session
        @executed = []
      end

      attr_reader :req
      attr_reader :account
      attr_reader :login_session
      attr_reader :executed

      def execute_transaction(commands = req.commands)
        commands.each do |command|
          receive(command)
        end
      end

      def receive(command)
        if COMMANDS.include?(command)
          execute(command)
        end
      end

      def execute(command)
        if respond_to?(command)
          __send__(command)
          executed << command
        end
      end

      def disable
        account.disable
      end

      def enable
        account.enable
      end

      def ident
        unless account.found?
          @account = @account.create(req)
        end
        if !account.locked? || req.unlocked?(account.vuk)
          account.setkey(req.idk)
          if req.suk && req.vuk
            account.setlock(req.suk, req.vuk)
          end
        end
        login_session.login(account)
        login_session.unlink if req.opt?('cps')
      end

      def query; end

      def remove
        account.remove
      end

      def self.supported_commands
        COMMANDS.select {|command| instance_methods.include? command.to_sym}
      end

      def self.unsupported_commands
        COMMANDS - supported_commands
      end

      def self.recognized_commands
        COMMANDS
      end

      COMMANDS = %w[
        disable
        enable
        ident
        remove
        query
      ]
    end
  end
end
