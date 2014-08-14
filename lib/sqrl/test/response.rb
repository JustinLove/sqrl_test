require 'sqrl/test/commands'
require 'sqrl/test/server_sessions'
require 'sqrl/test/server_key'
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
        @req.login_ip = login_ip
        p @req.client_data
        @command_failed = !valid?
        @sqrl_failure = !valid?
        @commands = Commands.new(@req)
      end

      def valid?
        @req.valid?
      end

      def session
        @session ||= ServerSessions.for_idk(@req.idk)
      end

      def login_ip
        if @param_nut
          SQRL::ReversibleNut.reverse(ServerKey, @param_nut).ip
        elsif session
          session[:ip]
        else
          @request_ip
        end
      end

      def logged_in?
        session && session[:status] == :logged_in
      end

      def server_unlock_key
        session && session[:suk]
      end

      def execute_commands
        return unless valid?

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
          :id_match => !!session.found?,
          :ip_match => @request_ip == login_ip,
          :login_enabled => !!session.found?,
          :logged_in => logged_in?,
          :creation_allowed => !ServerSessions.for_ip(login_ip).found?,
          :command_failed => @command_failed,
          :sqrl_failure => @sqrl_failure,
        }
      end

      def response(base = 16)
        res_nut = SQRL::OpaqueNut.new
        response = SQRL::AuthenticationResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :suk => server_unlock_key,
          :signature_valid => valid?,
          :recognized_commands => @commands.recognized.join(','),
          :unrecognized_commands => @commands.unrecognized.join(','),
          :executed_commands => @commands.executed.join(','),
          :sessions => ServerSessions.list,
          :request_ip => @request_ip,
          :login_ip => login_ip
        }.merge(flags))
        response.tif_base = base
        response
      end
    end
  end
end
