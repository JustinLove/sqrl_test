require 'ostruct'
require 'sqrl/base64'
require 'sqrl/key/verify_unlock'

module SQRL
  module Test
    class Account < OpenStruct
      def found?; true; end

      def locked?
        self[:suk] && self[:vuk]
      end

      def enabled?
        self[:status] != :disabled
      end

      def disabled?
        self[:status] == :disabled
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

      def disable
        self[:status] = :disabled
      end

      def enable
        self[:status] = :known
      end

      def remove
        self[:idk] = nil
        self[:suk] = nil
        self[:vuk] = nil
      end

      def create(req)
        raise "Cannot create account from an existing account"
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
