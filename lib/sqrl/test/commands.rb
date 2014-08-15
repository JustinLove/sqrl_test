require 'sqrl/test/null_session'
require 'sqrl/test/server_sessions'

module SQRL
  module Test
    class Commands
      def initialize(req, session)
        @req = req
        @session = session
        @executed = []
        @recognized = []
        @unrecognized = []
      end

      attr_reader :session
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
        session.setkey(@req.idk)
      end

      def setlock
        session.setlock(@req.suk, @req.vuk)
      end

      def create
        return false if session.found?
        @session = ServerSessions.create(@req)
        true
      end

      def login
        session.login(@req.login_ip)
      end

      def logout
        session.logout
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
