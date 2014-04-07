require 'sinatra/base'
require 'sqrl/opaque_nut'
require 'sqrl/url'

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
          :auth_url => SQRL::URL.new('example.com/sqrl', nut)
        }
      end
    end
  end
end
