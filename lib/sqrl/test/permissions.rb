require 'set'

module SQRL
  module Test
    class Permissions
      def initialize(req, session)
        @req = req
        self.session = session
        @errors = Set.new
      end

      attr_reader :req
      attr_reader :session

      attr_reader :errors

      def session=(session)
        @session = session
        @session_found = session.found?
        @unlocked = nil
      end

      def allow?(command)
        query = command + '?'
        __send__(query) if respond_to?(query)
      end

      def allowed_commands(commands = req.commands)
        commands.select { |command|
          if allow?(command)
            pusedo_execute(command)
            true
          end
        }
      end

      def allow_transaction?(commands = req.commands)
        commands == allowed_commands(commands)
      end

      def setkey?
        ids? && unlocked? && session? && idk?
      end

      def setlock?
        ids? && unlocked? && session? && suk? && vuk?
      end

      def create?
        ids? && no_session?
      end

      def login?
        ids? && session?
      end

      def logout?
        ids? && session?
      end
      alias_method :logoff?, :logout?

      private

      def ids?
        @ids_valid ||= req.valid?
        errors << "Identity signature not valid" unless @ids_valid
        @ids_valid
      end

      def unlocked?
        @unlocked ||= !session.locked? || req.unlocked?(session.vuk)
        errors << "Session is locked and unlock signature not valid" unless @unlocked
        @unlocked
      end

      def session?
        errors << "Session required" unless @session_found
        @session_found
      end

      def no_session?
        errors << "Session already exists" if @session_found
        !@session_found
      end

      def idk?
        errors << "IDK required" unless req.idk
        !!req.idk
      end

      def suk?
        errors << "SUK required" unless req.suk
        !!req.suk
      end

      def vuk?
        errors << "VUK required" unless req.vuk
        !!req.vuk
      end

      # psuedo execution
      def pusedo_execute(command)
        __send__(command) if respond_to?(command, true)
      end

      def setlock
        @unlocked = req.unlocked?(session.vuk)
      end

      def create
        @session_found = true
        @unlocked = true
      end
    end
  end
end
