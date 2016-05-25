require 'sinatra/base'
require 'rqrcode'
require 'sqrl/test/manual_sessions'
require 'sqrl/test/null_session'
require 'sqrl/test/web_session'
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
      enable :sessions

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
        login_session = ManualSessions.fetch(session_id, request.ip)
        ManualSessions.sqrl_record(auth_url, login_session)
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
        ManualSessions.fetch(session_id, request.ip).logout
        redirect to('/')
      end

      get '/token/:token' do |token|
        ses = ManualSessions.token_consume(token)
        if ses.found?
          ses.id = session_id
          ManualSessions.save(ses)
        end
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
          ManualSessions.expire!
          login_session = ManualSessions.sqrl_consume(req.server_string)
          response = Response.new(req, request.ip, login_session.ip, login_session)
          response.execute_commands
          res = response.response((params[:tif_base] || 16).to_i)
          res.fields['qry'] = '/sqrl'
          if req.opt?('cps') && !req.commands.include?('query')
            res.fields['url'] = "#{request.base_url}/token/#{login_session.generate_token}"
          end
          if login_session.found?
            ManualSessions.sqrl_record(res.server_string, login_session)
          else
            ManualSessions.sqrl_record(res.server_string, WebSession.new({'ip' => request.ip}))
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
            ManualSessions.sqrl_record(res.server_string, login_session)
          else
            ManualSessions.sqrl_record(res.server_string, WebSession.new({'ip' => request.ip}))
          end
          status 500
          return res.response_body
        end
      end

      def session_id
        session['id'] ||= SecureRandom.urlsafe_base64
      end
    end
  end
end
