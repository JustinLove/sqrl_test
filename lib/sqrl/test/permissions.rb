require 'set'

module SQRL
  module Test
    class Permissions
      def initialize(req, session)
        @req = req
        @session = session
        @errors = Set.new
      end

      attr_reader :req
      attr_accessor :session

      attr_reader :errors

      def allow?(command)
        query = command + '?'
        __send__(query) if respond_to?(query)
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
        errors << "Session required" unless session.found?
        session.found?
      end

      def no_session?
        errors << "Session already exists" if session.found?
        !session.found?
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
    end
  end
end
