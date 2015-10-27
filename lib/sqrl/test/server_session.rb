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
