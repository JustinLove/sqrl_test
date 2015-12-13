require 'sinatra/base'
require 'rqrcode'
require 'sqrl/test/pending_sessions'
require 'sqrl/test/web_session'
require 'sqrl/test/sqrl_only_session'
require 'sqrl/test/response'
require 'sqrl/test/panic_response'
require 'sqrl/opaque_nut'
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
      #enable :session
      class Rack::Session::Pool
        def call(env)
          env['session.object'] = self
          super
        end
      end
      use Rack::Session::Pool, :expire_after => 2592000

      configure do 
        STDOUT.sync = true
      end

      get '/' do
        nut = SQRL::OpaqueNut.new.to_s
        auth_url = SQRL::URL.qrl(request.host+':'+request.port.to_s+'/sqrl', {
          :nut => nut, :sfn => 'SQRL::Test'}).to_s
        if params[:tif_base]
          auth_url += '&tif_base=' + params[:tif_base]
        end
        login_session = WebSession.new(session, request.ip)
        PendingSessions.record(auth_url, login_session)
        if login_session.logged_in?
          account = Accounts.for_idk(login_session.idk)
          erb :logged_in, :locals => {
            :props => account.to_h_printable,
          }
        else
          erb :index, :locals => {
            :auth_url => auth_url,
            :tif_base => params[:tif_base],
            :qr => RQRCode::QRCode.new(auth_url, :size => 5, :level => :l),
          }
        end
      end

      get '/logout' do
        Accounts.for_ip(request.ip).logout
        redirect to('/')
      end

      post '/sqrl.html' do
        nut = params[:nut]
        req = SQRL::QueryParser.new(request.body.read)
        props = Hash[RequestProperties.map {|prop| [prop, req.__send__(prop)]}]
        props['signature valid'] = req.valid?
        props['secure?'] = request.secure?
        props['post ip'] = request.ip
        props['url'] = request.url
        props['fullpath'] = request.fullpath
        props['nut'] = nut
        props['methods'] = request.methods.sort - Object.instance_methods
        erb :report, :locals => {
          :req => req,
          :props => props
        }
      end

      post '/sqrl' do
        login_session = NullSession
        begin
          req = SQRL::QueryParser.new(request.body.read)
          p req.client_data
          PendingSessions.expire!
          login_session = PendingSessions.consume(req.server_string)
          response = Response.new(req, request.ip, login_session.ip, login_session)
          response.execute_commands
          res = response.response((params[:tif_base] || 16).to_i)
          res.fields['qry'] = '/sqrl'
          if login_session.found?
            PendingSessions.record(res.server_string, login_session)
          else
            PendingSessions.record(res.server_string, SqrlOnlySession.new(session, request.ip))
          end
          puts res.server_string
          puts res.response_body
          return res.response_body
        rescue => e
          puts "#{e.class}: #{e.message}\n"
          puts e.backtrace.map { |l| "\t#{l}" }.join("\n")

          response = PanicResponse.new(request.body.read, request.ip)
          res = response.response((params[:tif_base] || 16).to_i)
          res.fields['qry'] = '/sqrl'
          if login_session.found?
            PendingSessions.record(res.server_string, login_session)
          else
            PendingSessions.record(res.server_string, SqrlOnlySession.new(session, request.ip))
          end
          status 500
          return res.response_body
        end
      end
    end
  end
end
