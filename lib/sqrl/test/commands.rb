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

      def setkey
        ServerSessions.for_ip(@login_ip).setkey(@req.idk)
      end

      def setlock
        ServerSessions.for_idk(@req.idk).setlock(@req.suk, @req.vuk)
      end

      def create
        ServerSessions.create(@login_ip)
      end

      def login
        session = ServerSessions.for_idk(@req.idk)
        return false unless session.found?
        session.login(@login_ip)
      end

      def logout
        ServerSessions.for_idk(@req.idk).logout
      end
      alias_method :logoff, :logout

      COMMANDS = %w[
        setkey
        setlock
        disable
        enable
        delete
        create
        login
        logme
        logout
        logoff
      ]
    end
  end
end
