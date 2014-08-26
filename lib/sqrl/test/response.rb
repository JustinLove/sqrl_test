require 'sqrl/test/commands'
require 'sqrl/test/permissions'
require 'sqrl/test/server_sessions'
require 'sqrl/test/server_key'
require 'sqrl/query_parser'
require 'sqrl/response_generator'
require 'sqrl/opaque_nut'

module SQRL
  module Test
    class Response
      def initialize(request_body, request_ip, param_nut)
        @request_ip = request_ip
        @param_nut = param_nut
        @req = SQRL::QueryParser.new(request_body)
        @req.login_ip = login_ip
        p @req.client_data
        @command_failed = !valid?
        @sqrl_failure = !valid?
        @session = ServerSessions.for_idk(@req.idk)
        @commands = Commands.new(@req, @session)
        @permissions = Permissions.new(@req, @session)
      end

      attr_reader :session

      def valid?
        @req.valid?
      end

      def locked?
        session.locked? && !@req.unlocked?(session.vuk)
      end

      def login_ip
        if @param_nut
          SQRL::ReversibleNut.reverse(ServerKey, @param_nut).ip
        elsif session.found?
          session[:ip]
        else
          @request_ip
        end
      end

      def logged_in?
        session[:status] == :logged_in
      end

      def server_unlock_key
        session[:suk]
      end

      def execute_commands
        if @permissions.allow_transaction?
          @commands.execute_transaction
          @session = @commands.session
          @command_failed = true if @commands.unexecuted?
        else
          @sqrl_failure = @command_failed = true
        end
      end

      def flags
        @flags ||= {
          :id_match => session.found?,
          :ip_match => @request_ip == login_ip,
          :login_enabled => session.found?,
          :logged_in => logged_in?,
          :creation_allowed => !session.found?,
          :command_failed => @command_failed,
          :sqrl_failure => @sqrl_failure,
        }
      end

      def response(base = 16)
        res_nut = SQRL::OpaqueNut.new
        response = SQRL::ResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :suk => server_unlock_key,
          :signature_valid => valid?,
          :locked => locked?,
          :recognized_commands => (@req.commands & Commands::COMMANDS).join(','),
          :unrecognized_commands => (@req.commands - Commands::COMMANDS).join(','),
          :executed_commands => @commands.executed.join(','),
          :unexecuted_commands => @commands.unexecuted.join(','),
          :ask => @permissions.errors.to_a.join(','),
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
