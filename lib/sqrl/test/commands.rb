module SQRL
  module Test
    class Commands
      def initialize(req, login_ip)
        @req = req
        @login_ip = login_ip
        @executed = []
        @recognized = []
        @unrecognized = []
      end

      attr_reader :executed
      attr_reader :recognized
      attr_reader :unrecognized

      def unrecognized?
        unrecognized.length > 0
      end

      def unexecuted?
        executed != recognized
      end

      def receive(command)
        if COMMANDS.include?(command)
          recognized << command
          execute(command)
        else
          unrecognized << command
        end
      end

      def execute(command)
        if respond_to?(command)
          if __send__(command)
            executed << command
          end
        end
      end

      def setlock
        ServerSession.setlock(@login_ip, @req.idk, @req.suk, @req.vuk)
      end

      def login
        ServerSession.login(@login_ip, @req.idk)
      end

      def logoff
        ServerSession.logoff(@login_ip, @req.idk)
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
