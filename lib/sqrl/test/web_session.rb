module SQRL
  module Test
    class WebSession
      def initialize(session, ip)
        @session = session
        @ip = ip
        touch
      end

      def self.sub(ip)
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

      def login(account)
        @session['idk'] = account.idk
      end

      def logout
        @session.delete('idk')
      end

      def logged_in?
        @session['idk']
      end

      def idk
        @session['idk']
      end

      private
      attr_reader :ts

      def age_in_seconds
        Time.now - ts
      end
    end
  end
end
