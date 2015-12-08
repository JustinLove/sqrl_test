require 'sqrl/test/commands'
require 'sqrl/test/permissions'
require 'sqrl/test/accounts'
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
        @account = Accounts.for_idk(@req.idk)
        @req.login_ip = login_ip
      end

      attr_reader :account

      def valid?
        @req.valid?
      end

      def locked?
        account.locked? && !@req.unlocked?(account.vuk)
      end

      def login_ip
        @login_ip ||= if param_nut
          param_nut.ip
        elsif account.found?
          account[:ip]
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
        account[:suk]
      end

      def execute_commands
        permissions = Permissions.new(@req, @account)
        @errors += permissions.errors.to_a
        @allowed_commands = permissions.allowed_commands
        @disallowed_commands = @req.commands - @allowed_commands

        if nut_age > 60*30
          @errors << "Expired Nut"
          @client_failure = @command_failed = @transient_error = true
        elsif @allowed_commands == @req.commands
          commands = Commands.new(@req, @account)
          commands.execute_transaction
          @account = commands.account
          @executed_commands = commands.executed
          @unexecuted_commands = @req.commands - @executed_commands
          @command_failed = true if @executed_commands != @req.commands
        else
          @client_failure = @command_failed = true
        end
      end

      def flags
        @flags ||= {
          :id_match => account.idk == @req.idk,
          :ip_match => @request_ip == login_ip,
          :sqrl_disabled => account.disabled?,
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
          :accounts => Accounts.list,
          :request_ip => @request_ip,
          :login_ip => login_ip
        }.merge(flags))
        response.tif_base = base
        response
      end
    end
  end
end
