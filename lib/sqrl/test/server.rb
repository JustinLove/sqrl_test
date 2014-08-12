require 'sinatra/base'
require 'rqrcode'
require 'sqrl/test/response'
require 'sqrl/test/server_key'
require 'sqrl/reversible_nut'
require 'sqrl/url'

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
      enable :session

      configure do 
        mime_type :ics, 'text/calendar'
        STDOUT.sync = true
      end

      get '/' do
        nut = SQRL::ReversibleNut.new(ServerKey, request.ip).to_s
        auth_url = SQRL::URL.qrl(request.host+':'+request.port.to_s+'/sqrl', nut).to_s
        if params[:tif_base]
          auth_url += '&tif_base=' + params[:tif_base]
        end
        ss = ServerSession.for_ip(request.ip)
        if ss && ss[:status] == :logged_in
          erb :logged_in, :locals => {
            :props => ss,
          }
        else
          erb :index, :locals => {
            :auth_url => auth_url,
            :qr => RQRCode::QRCode.new(auth_url, :size => 10),
          }
        end
      end

      get '/logoff' do
        if ss = ServerSession.for_ip(request.ip)
          ss[:status] = :logged_off
        end
        redirect to('/')
      end

      post '/sqrl.html' do
        nut = SQRL::ReversibleNut.reverse(ServerKey, params[:nut])
        req = SQRL::AuthenticationQueryParser.new(request.body.read)
        props = Hash[RequestProperties.map {|prop| [prop, req.__send__(prop)]}]
        props['signature valid'] = req.valid?
        props['secure?'] = request.secure?
        props['post ip'] = request.ip
        props['url'] = request.url
        props['fullpath'] = request.fullpath
        props['nut'] = params[:nut]
        props['login ip'] = nut.ip
        props['age'] = nut.age
        props['methods'] = request.methods.sort - Object.instance_methods
        erb :report, :locals => {
          :req => req,
          :props => props
        }
      end

      post '/sqrl' do
        response = Response.new(request.body.read, request.ip, params[:nut])
        response.execute_commands
        res = response.response((params[:tif_base] || 16).to_i)
        puts res.server_string
        puts res.response_body
        return res.response_body
      end
    end
  end
end
