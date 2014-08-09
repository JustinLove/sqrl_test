$server_sessions = []

module SQRL
  module Test
    module ServerSession
      extend self

      def for_ip(ip)
        $server_sessions.find {|s| s[:ip] == ip}
      end

      def for_idk(idk)
        $server_sessions.find {|s| s[:idk] == idk}
      end

      def list
        $server_sessions.join(',')
      end

      def assert(ip, idk, nut)
        if session = for_idk(idk)
          session[:ip] = ip
        else
          create(ip, idk, nut)
        end
      end

      def login(ip, idk)
        session = for_idk(idk)
        return unless session
        session[:ip] = ip
        session[:status] = :logged_in
      end

      def create(ip, idk, nut)
        $server_sessions << {:ip => ip, :idk => idk, :nut => nut, :status => :known}
      end
    end
  end
end
