require 'sqrl/test/web_session'
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

      def consume(server_string)
        expire!
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
