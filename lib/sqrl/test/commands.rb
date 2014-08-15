require 'sqrl/test/null_session'
require 'sqrl/test/server_sessions'

module SQRL
  module Test
    class Commands
      def initialize(req, session)
        @req = req
        @session = session
        @ids_valid = req.valid?
        @urs_valid = true
        @recognized = []
        @unrecognized = []
        @executed = []
      end

      attr_reader :req
      attr_reader :session
      attr_reader :recognized
      attr_reader :unrecognized
      attr_reader :executed

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
          if __send__("allow_#{command}?")
            __send__(command)
            executed << command
          end
        end
      end

      def allow_setkey?
        @ids_valid && @urs_valid && session.found? && req.idk
      end
      def setkey
        session.setkey(req.idk)
      end

      def allow_setlock?
        @ids_valid && @urs_valid && session.found? && req.suk && req.vuk
      end
      def setlock
        session.setlock(req.suk, req.vuk)
      end

      def allow_create?
        @ids_valid && !session.found?
      end
      def create
        @session = ServerSessions.create(req)
      end

      def allow_login?
        @ids_valid && session.found?
      end
      def login
        session.login(req.login_ip)
      end

      def allow_logout?
        @ids_valid && session.found?
      end
      alias_method :allow_logoff?, :allow_logout?
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
