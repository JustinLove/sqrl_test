require 'sqrl/query_parser'
require 'sqrl/response_generator'
require 'sqrl/ask'
require 'sqrl/opaque_nut'

module SQRL
  module Test
    class PanicResponse
      def initialize(request_body, request_ip)
        @request_ip = request_ip
        @req = SQRL::QueryParser.new(request_body)
        p @req.client_data
      end

      attr_reader :account

      def valid?
        @req.valid?
      end

      def flags
        @flags ||= {
          :command_failed => true,
        }
      end

      def response(base = 16)
        res_nut = SQRL::OpaqueNut.new.to_s
        response = SQRL::ResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :signature_valid => valid?,
          :ask => SQRL::Ask.new("Server Error"),
          :request_ip => @request_ip,
        }.merge(flags))
        response.tif_base = base
        response
      end
    end
  end
end
