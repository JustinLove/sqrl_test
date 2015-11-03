require 'sinatra/base'
require 'rqrcode'
require 'sqrl/test/response'
require 'sqrl/test/server_key'
require 'sqrl/reversible_nut'
require 'sqrl/url'
require 'sqrl/base64'

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
        auth_url = SQRL::URL.qrl(request.host+':'+request.port.to_s+'/sqrl', {
          :nut => nut, :sfn => 'SQRL::Test'}).to_s
        if params[:tif_base]
          auth_url += '&tif_base=' + params[:tif_base]
        end
        ss = ServerSessions.for_ip(request.ip)
        if ss[:status] == :logged_in
          erb :logged_in, :locals => {
            :props => ss.to_h_printable,
          }
        else
          erb :index, :locals => {
            :auth_url => auth_url,
            :tif_base => params[:tif_base],
            :qr => RQRCode::QRCode.new(auth_url, :size => 4, :level => :l),
          }
        end
      end

      get '/logout' do
        ServerSessions.for_ip(request.ip).logout
        redirect to('/')
      end

      post '/sqrl.html' do
        nut = SQRL::ReversibleNut.reverse(ServerKey, params[:nut])
        req = SQRL::QueryParser.new(request.body.read)
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
        res.fields['qry'] = '/sqrl'
        puts res.server_string
        puts res.response_body
        return res.response_body
      end
    end
  end
end
