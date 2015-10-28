require 'sqrl/test/server_sessions'

module SQRL
  module Test
    module NullSession
      extend self

      def [](key); nil; end
      def []=(key, value); value; end

      def vuk; nil; end
      def suk; nil; end

      def found?; false; end
      def locked?; false; end
      def setkey(idk); end
      def setlock(suk, vuk); end
      def login(ip); end

      def create(req)
        ServerSessions.create(req)
      end

      def to_s; 'NullSession'; end
    end
  end
end
