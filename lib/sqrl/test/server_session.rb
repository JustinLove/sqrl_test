require 'ostruct'
require 'sqrl/base64'

module SQRL
  module Test
    class ServerSession < OpenStruct
      def found?; true; end

      def setkey(req)
        self[:idk] = req.idk
        !!idk
      end

      def setlock(req)
        self[:suk] = req.suk
        self[:vuk] = req.vuk
        !!(suk && vuk)
      end

      def login(req)
        self[:ip] = req.login_ip
        self[:status] = :logged_in
        true
      end

      def logout
        self[:ip] = nil
        self[:status] = :logged_out
        true
      end

      def to_s
        to_h.map {|k,v|
          v = Base64.encode(v) if v.kind_of?(String) && v.match(/[^[:print:]]|=/)
          [k,v].join(':')
        }.join(', ')
      end
    end
  end
end
