module SQRL
  module Test
    class SqrlOnlySession
      def initialize(session, ip)
        @session = session
        @ip = ip
        touch
      end

      attr_reader :ip

      def found?
        @session && !expired?
      end

      def touch
        @ts = Time.now
      end

      def expired?
        age_in_seconds > 60*30
      end

      def login(account); end
      def logout; end
      def logged_in?; false; end
      def login_capable?; false; end
      def idk; ''; end

      private
      attr_reader :ts

      def age_in_seconds
        Time.now - ts
      end
    end
  end
end
