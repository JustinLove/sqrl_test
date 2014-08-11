require 'base64'

module SQRL
  module Test
    ServerKey = Base64.urlsafe_decode64(ENV['SERVER_KEY'])
  end
end
