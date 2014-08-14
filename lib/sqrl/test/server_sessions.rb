require 'sqrl/test/server_session'
require 'sqrl/test/null_session'

$server_sessions = []

module SQRL
  module Test
    module ServerSessions
      extend self

      def for_ip(ip)
        $server_sessions.find {|s| s[:ip] == ip} || NullSession
      end

      def for_idk(idk)
        $server_sessions.find {|s| s[:idk] == idk} || NullSession
      end

      def list
        $server_sessions.join(';')
      end

      def create(ip)
        return false if for_ip(ip).found?
        $server_sessions << ServerSession.new(:ip => ip, :status => :known)
      end
    end
  end
end
