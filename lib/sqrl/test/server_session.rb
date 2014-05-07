$server_sessions = []

module SQRL
  module Test
    module ServerSession
      extend self

      def for_ip(ip)
        $server_sessions.find {|s| s[:ip] == ip}
      end

      def list
        $server_sessions.join(',')
      end

      def login(ip, idk)
        $server_sessions << {:ip => ip, :idk => idk}
      end
    end
  end
end
