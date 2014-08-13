require 'sqrl/base64'

module SQRL
  module Test
    ServerKey = Base64.decode(ENV['SERVER_KEY'])
  end
end
