require 'sinatra/base'
require 'rqrcode'
require 'sqrl/reversible_nut'
require 'sqrl/url'
require 'sqrl/authentication_query_parser'
require 'sqrl/authentication_response_generator'

module SQRL
  module Test
    RequestProperties = %w[
      params
      server_string
      client_data
      message
      valid?
    ]
    class Server < Sinatra::Base
      configure do 
        mime_type :ics, 'text/calendar'
        STDOUT.sync = true
      end

      get '/' do
        nut = SQRL::ReversibleNut.new(ENV['SERVER_KEY'], request.ip).to_s
        auth_url = SQRL::URL.qrl(request.host+':'+request.port.to_s+'/sqrl', nut).to_s
        erb :index, :locals => {
          :auth_url => auth_url,
          :qr => RQRCode::QRCode.new(auth_url, :size => 10)
        }
      end

      post '/sqrl.html' do
        nut = SQRL::ReversibleNut.reverse(ENV['SERVER_KEY'], params[:nut])
        req = SQRL::AuthenticationQueryParser.new(request.body.read)
        props = Hash[RequestProperties.map {|prop| [prop, req.__send__(prop)]}]
        props['secure?'] = request.secure?
        props['post ip'] = request.ip
        props['nut'] = params[:nut]
        props['login ip'] = nut.ip
        props['age'] = nut.age
        erb :report, :locals => {
          :req => req,
          :props => props
        }
      end

      post '/sqrl' do
        req_nut = SQRL::ReversibleNut.reverse(ENV['SERVER_KEY'], params[:nut])
        req = SQRL::AuthenticationQueryParser.new(request.body.read)
        invalid = !req.valid?
        res_nut = req_nut.response_nut
        flags =  {
          :ip_match => request.ip == req_nut.ip,
          :command_failed => invalid,
          :sqrl_failure => invalid,
        }
        response = SQRL::AuthenticationResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
        }.merge(flags))
        response.response_body
      end
    end
  end
end
