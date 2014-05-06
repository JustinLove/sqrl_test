require 'sinatra/base'
require 'rqrcode'
require 'sqrl/reversible_nut'
require 'sqrl/url'
require 'sqrl/authentication_query_parser'
require 'sqrl/authentication_response_generator'

COMMANDS = %w[
  setkey
  setlock
  disable
  enable
  delete
  create
  login
  logme
  logoff
]

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
        req_nut = SQRL::ReversibleNut.reverse(ENV['SERVER_KEY'], params[:nut])
        req = SQRL::AuthenticationQueryParser.new(request.body.read)
        valid = req.valid?
        command_failed = !valid
        sqrl_failure = !valid
        executed_commands = []
        recognized_commands = []
        unrecognized_commands = []

        req.commands.each do |command|
          if COMMANDS.include?(command)
            recognized_commands << command
          else
            unrecognized_commands << command
          end

          case command
          when 'login'
            executed_commands << command
            $sessions |= [req_nut.ip]
          end
        end

        if unrecognized_commands.length > 0
          sqrl_failure = command_failed = true
        elsif executed_commands != recognized_commands
          command_failed = true
        end

        res_nut = req_nut.response_nut
        flags =  {
          :ip_match => request.ip == req_nut.ip,
          :command_failed => command_failed,
          :sqrl_failure => sqrl_failure,
          :logged_in => $sessions.include?(req_nut.ip),
        }
        response = SQRL::AuthenticationResponseGenerator.new(res_nut, flags, {
          :sfn => 'SQRL::Test',
          :signature_valid => valid,
          :recognized_commands => recognized_commands.join(','),
          :unrecognized_commands => unrecognized_commands.join(','),
          :executed_commands => executed_commands.join(','),
          :sessions => $sessions.join(','),
        }.merge(flags))
        response.response_body
      end
    end
  end
end
