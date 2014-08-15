require 'ostruct'
require 'sqrl/base64'

module SQRL
  module Test
    class ServerSession < OpenStruct
      def found?; true; end

      def setkey(idk)
        self[:idk] = idk
        !!idk
      end

      def setlock(suk, vuk)
        self[:suk] = suk
        self[:vuk] = vuk
        !!(suk && vuk)
      end

      def login(ip)
        self[:ip] = ip
        self[:status] = :logged_in
        true
      end

      def logout
        self[:ip] = nil
        self[:status] = :logged_out
        true
      end

      def to_s
        to_h_printable.map {|pair| pair.join(':')}.join(', ')
      end

      def to_h_printable
        h = to_h
        h.each_pair {|k,v|
          h[k] = Base64.encode(v) if v.kind_of?(String) && v.match(/[^[:print:]]|=/)
        }
        h
      end
    end
  end
end
