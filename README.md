# Sqrl::Test

Simple web app to test SQRL clients

## Installation

Add this line to your application's Gemfile:

    gem 'sqrl_test'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sqrl_test

## Usage

Demo server: http://sqrl-test.herokuapp.com

Visit `/` for the qr-code.

For certain clients, you may need to append `?tif_base=10`

Session state (including "user accounts") is stored in memory and will frequently reset.

### Supported Commands:

- ident
- query

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
