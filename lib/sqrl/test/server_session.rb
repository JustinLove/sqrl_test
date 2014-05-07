$server_sessions = []

module SQRL
  module Test
    module ServerSession
      extend self

      def for_ip(ip)
        $server_sessions.find {|s| s[:ip] == ip}
      end

      def list
        $server_sessions.map {|s| s[:ip]}.join(',')
      end

      def login(ip)
        $server_sessions << {:ip => ip}
      end
    end
  end
end
