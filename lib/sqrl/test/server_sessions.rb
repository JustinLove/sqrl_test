require 'sqrl/test/server_session'
require 'sqrl/test/null_session'

$server_sessions = []

module SQRL
  module Test
    module ServerSessions
      extend self

      def for_ip(ip)
        find_ip(ip) || NullSession
      end

      def for_idk(idk)
        find_idk(idk) || NullSession
      end

      def lookup(req)
        find_idk(req.idk) || find_ip(req.login_ip) || NullSession
      end

      def list
        $server_sessions.join(';')
      end

      def create(req)
        session = ServerSession.new(:ip => req.login_ip, :status => :known)
        $server_sessions << session
        session
      end

      private
      def find_ip(ip)
        $server_sessions.find {|s| s[:ip] == ip}
      end

      def find_idk(idk)
        $server_sessions.find {|s| s[:idk] == idk}
      end
    end
  end
end
