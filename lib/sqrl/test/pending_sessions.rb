require 'sqrl/test/null_session'

module SQRL
  module Test
    module PendingSessions
      @@sessionmap = {}

      extend self

      def expire!
        @@sessionmap.keys.each do |server|
          if @@sessionmap[server].expired?
            @@sessionmap.delete(server)
          end
        end
      end

      def known?(server_string)
        @@sessionmap.has_key?(server_string)
      end

      def consume(server_string)
        @@sessionmap.delete(server_string) || NullSession
        #@@sessionmap[server_string] || NullSession
      end

      def record(server_string, session)
        session.touch
        @@sessionmap[server_string] = session
      end
    end
  end
end
