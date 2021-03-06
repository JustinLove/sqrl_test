require 'sqrl/test/web_session'

module SQRL
  module Test
    module ManualSessions
      @@sessions = []

      extend self

      def expire!
        @@sessions.delete_if do |ses|
          ts = ses['ts'] || 0
          Time.now - ts > 2592000
        end
      end

      def known?(id)
        @@sessions.has_key?(id)
      end

      def find(id)
        @@sessions.find {|ses| ses['id'] == id}
      end

      def fetch(id, ip)
        ses = find(id) || {'id' => id, 'ip' => ip}
        WebSession.new(ses)
      end

      def sqrl_consume(server_string)
        ses = @@sessions.find {|ses| ses['server_string'] == server_string}
        if ses
          ses.delete('server_string')
          WebSession.new(ses)
        else
          NullSession
        end
      end

      def sqrl_record(server_string, session)
        session.server_string = server_string
        save(session)
      end

      def token_consume(token)
        ses = @@sessions.find {|ses| ses['token'] == token}
        if ses
          ses.delete('token')
          WebSession.new(ses)
        else
          NullSession
        end
      end

      def save(session)
        return unless session.id
        session.touch
        ses = find(session.id)
        if ses
          ses.merge(session.to_h)
        else
          @@sessions.push(session.to_h)
        end
      end
    end
  end
end
