module SQRL
  module Test
    module NullSession
      extend self

      def [](key); nil; end
      def []=(key, value); value; end

      def found?; false; end
      def setkey(idk); end
      def setlock(suk, vuk); end
      def login(ip); end
      def logout; end

      def to_s; 'NullSession'; end
    end
  end
end
