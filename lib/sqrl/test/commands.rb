module SQRL
  module Test
    class Commands
      def initialize(ip)
        @ip = ip
        @executed = []
        @recognized = []
        @unrecognized = []
      end

      attr_reader :executed
      attr_reader :recognized
      attr_reader :unrecognized

      def execute(command)
        if COMMANDS.include?(command)
          recognized << command
          __send__(command) if respond_to?(command)
        else
          unrecognized << command
        end
      end

      def login
        executed << 'login'
        $sessions |= [@ip]
      end

      COMMANDS = %w[
        setkey
        setlock
        disable
        enable
        delete
        create
        login
        logme
        logoff
      ]
    end
  end
end
