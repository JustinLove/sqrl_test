require 'sqrl/test/commands'
require 'sqrl/test/server_session'
require 'sqrl/authentication_query_parser'
require 'sqrl/authentication_response_generator'
require 'sqrl/opaque_nut'

module SQRL
  module Test
    class Response
      def initialize(request_body, request_ip, param_nut)
        @request_ip = request_ip
        @param_nut = param_nut
        @req = SQRL::AuthenticationQueryParser.new(request_body)
        p @req.client_data
        @command_failed = !valid?
        @sqrl_failure = !valid?
        @commands = Commands.new(@req, login_ip)
      end

      def valid?
        @req.valid?
      end

      def session
        @session ||= ServerSession.for_idk(@req.idk)
      end

      def login_ip
        if @param_nut
          SQRL::ReversibleNut.reverse(ENV['SERVER_KEY'], @param_nut).ip
        elsif session
          session[:ip]
        else
          @request_ip
        end
      end

      def logged_in?
        session && session[:status] == :logged_in
      end

      def execute_commands
        return unless valid?

        ServerSession.assert(login_ip, @req.idk, @param_nut)

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
          :id_match => !!session,
          :ip_match => @request_ip == login_ip,
          :login_enabled => true,
          :logged_in => logged_in?,
          :command_failed => @command_failed,
          :sqrl_failure => @sqrl_failure,
        }
      end

      def response(base = 16)
        res_nut = SQRL::OpaqueNut.new
        response = SQRL::AuthenticationResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :signature_valid => valid?,
          :recognized_commands => @commands.recognized.join(','),
          :unrecognized_commands => @commands.unrecognized.join(','),
          :executed_commands => @commands.executed.join(','),
          :sessions => ServerSession.list,
          :request_ip => @request_ip,
          :login_ip => login_ip
        }.merge(flags))
        response.tif_base = base
        response
      end
    end
  end
end
