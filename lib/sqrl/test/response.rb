require 'sqrl/test/commands'
require 'sqrl/test/server_session'
require 'sqrl/authentication_query_parser'
require 'sqrl/authentication_response_generator'

module SQRL
  module Test
    class Response
      def initialize(request_body, request_ip, nut)
        @request_ip = request_ip
        @req_nut = SQRL::ReversibleNut.reverse(ENV['SERVER_KEY'], nut)
        @req = SQRL::AuthenticationQueryParser.new(request_body)
        @command_failed = !valid?
        @sqrl_failure = !valid?
        @commands = Commands.new(@req, @req_nut.ip)
      end

      def valid?
        @req.valid?
      end

      def logged_in?
        !!ServerSession.for_ip(@req_nut.ip)
      end

      def execute_commands
        @req.commands.each do |command|
          @commands.receive(command)
        end

        if @commands.unrecognized?
          @sqrl_failure = @command_failed = true
        elsif @commands.unexecuted?
          @command_failed = true
        end
      end

      def flags
        @flags ||= {
          :ip_match => @request_ip == @req_nut.ip,
          :command_failed => @command_failed,
          :sqrl_failure => @sqrl_failure,
          :logged_in => logged_in?,
        }
      end

      def response_body
        res_nut = @req_nut.response_nut
        response = SQRL::AuthenticationResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :signature_valid => valid?,
          :recognized_commands => @commands.recognized.join(','),
          :unrecognized_commands => @commands.unrecognized.join(','),
          :executed_commands => @commands.executed.join(','),
          :sessions => ServerSession.list,
        }.merge(flags))
        response.response_body
      end
    end
  end
end
