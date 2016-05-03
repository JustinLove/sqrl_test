require 'sqrl/test/commands'
require 'sqrl/test/permissions'
require 'sqrl/test/accounts'
require 'sqrl/query_parser'
require 'sqrl/response_generator'
require 'sqrl/ask'
require 'sqrl/opaque_nut'

module SQRL
  module Test
    class Response
      def initialize(req, request_ip, login_ip, login_session)
        @allowed_commands = []
        @disallowed_commands = []
        @executed_commands = []
        @unexecuted_commands = []
        @errors = []
        @transient_error = false

        @req = req
        @request_ip = request_ip
        @login_ip = login_ip
        @login_session = login_session
        @command_failed = !valid?
        @client_failure = !valid?
        @primary_account = Accounts.for_idk(@req.idk)
        @previous_account = Accounts.for_idk(@req.pidk)
        if @primary_account.found?
          @account = @primary_account
        else
          @account = @previous_account
        end
      end

      attr_reader :account
      attr_reader :login_session
      attr_reader :login_ip

      def valid?
        @req.valid?
      end

      def locked?
        account.locked? && !@req.unlocked?(account.vuk)
      end

      def server_string
        @req.server_string
      end

      def server_unlock_key
        account[:suk]
      end

      def execute_commands
        permissions = Permissions.new(@req, @account, @login_session)
        @allowed_commands = permissions.allowed_commands
        @disallowed_commands = @req.commands - @allowed_commands
        @errors += permissions.errors.to_a
        @transient_error = permissions.transient_error

        if @allowed_commands == @req.commands
          commands = Commands.new(@req, @account, @login_session)
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
          :id_match => @primary_account.idk == @req.idk,
          :previous_id_match => @previous_account.idk == @req.pidk,
          :ip_match => @request_ip == login_ip,
          :sqrl_disabled => account.disabled?,
          :function_not_supported => (@req.commands & Commands.unsupported_commands).any?,
          :transient_error => @transient_error,
          :command_failed => @command_failed,
          :client_failure => @client_failure,
        }
      end

      def response(base = 16)
        res_nut = SQRL::OpaqueNut.new.to_s
        flag = flags
        fields = {
          :sfn => 'SQRL::Test',
          :signature_valid => valid?,
          :nut_valid => @login_session.found?,
          :bound_to_login_session => @login_session.login_capable?,
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
        }.merge(flag)
        if account.disabled?
          fields[:suk] = server_unlock_key
        end
        response = SQRL::ResponseGenerator.new(res_nut, flag, fields)
        response.tif_base = base
        response
      end
    end
  end
end
