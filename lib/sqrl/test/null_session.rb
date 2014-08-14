module SQRL
  module Test
    module NullSession
      extend self

      def [](key); nil; end
      def []=(key, value); value; end

      def found?; false; end
      def setkey(req); false; end
      def setlock(req); false; end
      def login(req); false; end
      def logout; false; end

      def to_s; 'NullSession'; end
    end
  end
end
