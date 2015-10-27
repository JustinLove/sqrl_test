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
