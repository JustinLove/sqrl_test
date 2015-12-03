require 'sqrl/test/commands'
require 'sqrl/test/permissions'
require 'sqrl/test/server_sessions'
require 'sqrl/test/server_key'
require 'sqrl/query_parser'
require 'sqrl/response_generator'
require 'sqrl/ask'
require 'sqrl/opaque_nut'

module SQRL
  module Test
    class Response
      def initialize(request_body, request_ip, param_nut)
        @allowed_commands = []
        @disallowed_commands = []
        @executed_commands = []
        @unexecuted_commands = []
        @errors = []
        @transient_error = false

        @request_ip = request_ip
        @param_nut = param_nut
        @req = SQRL::QueryParser.new(request_body)
        p @req.client_data
        @command_failed = !valid?
        @client_failure = !valid?
        @session = ServerSessions.for_idk(@req.idk)
        @req.login_ip = login_ip
      end

      attr_reader :session

      def valid?
        @req.valid?
      end

      def locked?
        session.locked? && !@req.unlocked?(session.vuk)
      end

      def login_ip
        @login_ip ||= if param_nut
          param_nut.ip
        elsif session.found?
          session[:ip]
        else
          @request_ip
        end
      end

      def nut_age
        if param_nut
          param_nut.age
        else
          0
        end
      end

      def param_nut
        return nil unless @param_nut
        @reversed_nut ||= SQRL::ReversibleNut.reverse(ServerKey, @param_nut)
      rescue => e
        @errors << "Invalid nut"
        @errors << e.message
        @client_failure = @command_failed = @transient_error = true
        nil
      end

      def server_unlock_key
        session[:suk]
      end

      def execute_commands
        permissions = Permissions.new(@req, @session)
        @errors += permissions.errors.to_a
        @allowed_commands = permissions.allowed_commands
        @disallowed_commands = @req.commands - @allowed_commands

        if nut_age > 60*30
          @errors << "Expired Nut"
          @client_failure = @command_failed = @transient_error = true
        elsif @allowed_commands == @req.commands
          commands = Commands.new(@req, @session)
          commands.execute_transaction
          @session = commands.session
          @executed_commands = commands.executed
          @unexecuted_commands = @req.commands - @executed_commands
          @command_failed = true if @executed_commands != @req.commands
        else
          @client_failure = @command_failed = true
        end
      end

      def flags
        @flags ||= {
          :id_match => session.idk == @req.idk,
          :ip_match => @request_ip == login_ip,
          :sqrl_disabled => session.disabled?,
          :function_not_supported => (@req.commands & Commands.unsupported_commands).any?,
          :transient_error => @transient_error,
          :command_failed => @command_failed,
          :client_failure => @client_failure,
        }
      end

      def response(base = 16)
        res_nut = SQRL::OpaqueNut.new
        response = SQRL::ResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :suk => server_unlock_key,
          :signature_valid => valid?,
          :locked => locked?,
          :supported_commands => (@req.commands & Commands.supported_commands).join(','),
          :unsupported_commands => (@req.commands & Commands.unsupported_commands).join(','),
          :unrecognized_commands => (@req.commands - Commands.recognized_commands).join(','),
          :allowed_commands => @allowed_commands.join(','),
          :disallowed_commands => @disallowed_commands.join(','),
          :executed_commands => @executed_commands.join(','),
          :unexecuted_commands => @unexecuted_commands.join(','),
          :errors => @errors.join(','),
          :ask => SQRL::Ask.new(@errors.join(',')),
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
