require 'sinatra/base'
require 'rqrcode'
require 'sqrl/opaque_nut'
require 'sqrl/url'
require 'sqrl/login_request'

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
        nut = SQRL::OpaqueNut.new.to_s
        auth_url = SQRL::URL.new(request.host+'/sqrl', nut).to_s
        erb :index, :locals => {
          :auth_url => auth_url,
          :qr => RQRCode::QRCode.new(auth_url, :size => 10)
        }
      end

      post '/sqrl' do
        req = SQRL::LoginRequest.new(request.body.read)
        props = Hash[RequestProperties.map {|prop| [prop, req.__send__(prop)]}]
        erb :report, :locals => {
          :req => req,
          :props => props
        }
      end
    end
  end
end
