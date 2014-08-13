require 'sqrl/base64'

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
        $server_sessions.map{|s|
          s.map {|k,v|
            v = Base64.encode(v) if v.kind_of?(String) && v.match(/[^:print:]|=/)
            [k,v].join(':')
          }.join(', ')
        }.join(';')
      end

      def assert(ip, idk, nut)
        if session = for_idk(idk)
          session[:ip] = ip
        elsif for_ip(ip)
        else
          create(ip, nut)
        end
      end

      def setkey(ip, idk)
        if session = for_ip(ip) || for_idk(idk)
          session[:idk] = idk
          !!idk
        else
          false
        end
      end

      def setlock(ip, idk, suk, vuk)
        if session = for_idk(idk) || for_ip(ip)
          session[:suk] = suk
          session[:vuk] = vuk
          !!(suk && vuk)
        else
          false
        end
      end

      def login(ip, idk)
        session = for_idk(idk)
        return false unless session
        session[:ip] = ip
        session[:status] = :logged_in
        true
      end

      def logout(ip, idk)
        if session = for_idk(idk) || for_ip(ip)
          session[:status] = :logged_out
          true
        else
          false
        end
      end

      def create(ip, nut)
        $server_sessions << {:ip => ip, :nut => nut, :status => :known}
      end
    end
  end
end
