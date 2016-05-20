module SQRL
  module Test
    module NullSession
      extend self

      def found?; false; end

      def id; nil; end
      def touch; end
      def expired?; true; end
      def ip; ''; end
      def login(account); end
      def logout; end
      def logged_in?; false; end
      def idk; end
      def login_capable?; false; end
      def server_string=; end
    end
  end
end
