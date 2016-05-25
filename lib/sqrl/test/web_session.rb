require 'securerandom'

module SQRL
  module Test
    class WebSession
      def initialize(session)
        @session = session
        touch
      end

      def found?
        @session && !expired?
      end

      def id
        @session['id']
      end

      def id=(x)
        @session['id'] = x
      end

      def ip
        @session['ip']
      end

      def touch
        @session['ts'] = Time.now
      end

      def expired?
        age_in_seconds > 60*30
      end

      def login(account)
        @session['idk'] = account.idk if login_capable?
      end

      def logout
        @session.delete('idk')
      end

      def logged_in?
        @session['idk']
      end

      def unlink
        @session.delete('id')
      end

      def idk
        @session['idk']
      end

      def login_capable?
        !!id
      end

      def server_string=(ss)
        @session['server_string'] = ss
      end

      def generate_token
        @session['token'] = SecureRandom.urlsafe_base64
      end

      def token
        @session['token']
      end

      def to_h
        return @session
      end

      private

      def ts
        @session['ts']
      end

      def age_in_seconds
        Time.now - ts
      end
    end
  end
end
