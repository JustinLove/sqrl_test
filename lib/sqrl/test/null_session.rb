module SQRL
  module Test
    module NullSession
      extend self

      def [](key); nil; end
      def []=(key, value); value; end

      def found?; false; end
      def setkey(idk); false; end
      def setlock(suk, vuk); false; end
      def login(ip); false; end
      def logout; false; end

      def to_s; 'NullSession'; end
    end
  end
end
