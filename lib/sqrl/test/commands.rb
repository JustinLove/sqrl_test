module SQRL
  module Test
    class Commands
      def initialize(req, session)
        @req = req
        @session = session
        @executed = []
      end

      attr_reader :req
      attr_reader :session
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
        session.disable
      end

      def enable
        session.enable
      end

      def ident
        unless session.found?
          @session = @session.create(req)
        end
        if !session.locked? || req.unlocked?(session.vuk)
          session.setkey(req.idk)
          if req.suk && req.vuk
            session.setlock(req.suk, req.vuk)
          end
        end
        session.login(req.login_ip)
      end

      def query; end

      def remove
        session.remove
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
