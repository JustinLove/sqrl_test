module SQRL
  module Test
    class Commands
      def initialize(req, session)
        @req = req
        @session = session
        @recognized = []
        @executed = []
      end

      attr_reader :req
      attr_reader :session
      attr_reader :recognized
      attr_reader :executed

      def unexecuted
        recognized - executed
      end

      def unexecuted?
        executed != recognized
      end

      def execute_transaction(commands = req.commands)
        commands.each do |command|
          receive(command)
        end
      end

      def receive(command)
        if COMMANDS.include?(command)
          recognized << command
          execute(command)
        end
      end

      def execute(command)
        if respond_to?(command)
          __send__(command)
          executed << command
        end
      end

      def setkey
        session.setkey(req.idk)
      end

      def setlock
        session.setlock(req.suk, req.vuk)
      end

      def create
        @session = @session.create(req)
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
