require 'sqrl/test/server_sessions'
require 'sqrl/test/permissions'

module SQRL
  module Test
    class Commands
      def initialize(req, session)
        @req = req
        @session = session
        @permissions = Permissions.new(req, session)
        @recognized = []
        @unrecognized = []
        @executed = []
      end

      attr_reader :req
      attr_reader :session
      attr_reader :permissions
      attr_reader :recognized
      attr_reader :unrecognized
      attr_reader :executed

      def errors
        permissions.errors
      end

      def unexecuted
        recognized - executed
      end

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
          if permissions.allow?(command)
            __send__(command)
            executed << command
          end
        end
      end

      def setkey
        session.setkey(req.idk)
      end
      def setlock
        session.setlock(req.suk, req.vuk)
      end

      def create
        permissions.session = @session = ServerSessions.create(req)
      end

      def login
        session.login(req.login_ip)
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
