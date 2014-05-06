require 'sinatra/base'
require 'rqrcode'
require 'sqrl/test/response'
require 'sqrl/reversible_nut'
require 'sqrl/url'

$sessions = []

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
        if $sessions.include?(request.ip)
          erb :logged_in
        else
          erb :index, :locals => {
            :auth_url => auth_url,
            :qr => RQRCode::QRCode.new(auth_url, :size => 10),
          }
        end
      end

      post '/sqrl.html' do
        nut = SQRL::ReversibleNut.reverse(ENV['SERVER_KEY'], params[:nut])
        req = SQRL::AuthenticationQueryParser.new(request.body.read)
        props = Hash[RequestProperties.map {|prop| [prop, req.__send__(prop)]}]
        props['signature valid'] = req.valid?
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
        response = Response.new(request.body.read, request.ip, params[:nut])
        response.execute_commands
        return response.response_body
      end
    end
  end
end
