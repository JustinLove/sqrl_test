require 'ostruct'
require 'sqrl/base64'
require 'sqrl/key/verify_unlock'

module SQRL
  module Test
    class ServerSession < OpenStruct
      def found?; true; end

      def locked?
        self[:suk] && self[:vuk]
      end

      def vuk
        self[:vuk] && Key::VerifyUnlock.new(self[:vuk])
      end

      def setkey(idk)
        self[:idk] = idk
      end

      def setlock(suk, vuk)
        self[:suk] = suk
        self[:vuk] = vuk
      end

      def login(ip)
        self[:ip] = ip
        self[:status] = :logged_in
      end

      def logout
        self[:ip] = nil
        self[:status] = :logged_out
      end

      def create(req)
        raise "Cannot create session from an existing session"
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
