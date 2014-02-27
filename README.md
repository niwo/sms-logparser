# SmsLogparser

sms-logparser for DB-Logparser for Simplex Media Server

## Installation

Add this line to your application's Gemfile:

    gem 'sms-logparser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sms-logparser

## Setup

Create the database table to track which logs have been parsed:

    $ sms-logparser create_parser_table

Make a testrun:

    $ sms-logparser parse --simulate

## Usage

See available commamds:

    $ sms-logparser help

Parse logs from database and send them to the API

    $ sms-logparser parse

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
