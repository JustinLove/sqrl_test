require 'sinatra/base'
require 'sqrl/opaque_nut'
require 'sqrl/url'
require 'sqrl/login_request'

module SQRL
  module Test
    class Server < Sinatra::Base
      configure do 
        mime_type :ics, 'text/calendar'
        STDOUT.sync = true
      end

      get '/' do
        nut = SQRL::OpaqueNut.new.to_s
        erb :index, :locals => {
          :auth_url => SQRL::URL.new(request.host+'/sqrl', nut)
        }
      end

      post '/sqrl' do
        req = SQRL::LoginRequest.new(request.body.read)
        erb :report, :locals => {
          :req => req
        }
      end
    end
  end
end
