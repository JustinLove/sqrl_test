require 'sqrl/test/null_session'
require 'sqrl/test/server_sessions'
require 'set'

module SQRL
  module Test
    class Commands
      def initialize(req, session)
        @req = req
        @session = session
        @recognized = []
        @unrecognized = []
        @executed = []
        @errors = Set.new
      end

      attr_reader :req
      attr_reader :session
      attr_reader :recognized
      attr_reader :unrecognized
      attr_reader :executed
      attr_reader :errors

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
        ids? && urs? && session? && idk?
      end
      def setkey
        session.setkey(req.idk)
      end

      def allow_setlock?
        ids? && urs? && session? && suk? && vuk?
      end
      def setlock
        session.setlock(req.suk, req.vuk)
      end

      def allow_create?
        ids? && no_session?
      end
      def create
        @session = ServerSessions.create(req)
      end

      def allow_login?
        ids? && session?
      end
      def login
        session.login(req.login_ip)
      end

      def allow_logout?
        ids? && session?
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

      def ids?
        @ids_valid ||= req.valid?
        errors << "Identity signature not valid" unless @ids_valid
        @ids_valid
      end

      def urs?
        @urs_valid ||= true
        errors << "Unlock signature not valid" unless @urs_valid
        @urs_valid
      end

      def session?
        errors << "Session required" unless session.found?
        session.found?
      end

      def no_session?
        errors << "Session already exists" if session.found?
        !session.found?
      end

      def idk?
        errors << "IDK required" unless @req.idk
        !!@req.idk
      end

      def suk?
        errors << "SUK required" unless @req.suk
        !!@req.suk
      end

      def vuk?
        errors << "VUK required" unless @req.vuk
        !!@req.vuk
      end
    end
  end
end
