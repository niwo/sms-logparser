# SMS Logparser

sms-logparser - Logparser for Simplex Media Server (SMS). Reads access logs stored in a MySQL database (coming from the SWISS TXT CDN) and sends them to the SMS API.

[![Gem Version](https://badge.fury.io/rb/sms-logparser.png)](http://badge.fury.io/rb/sms-logparser)

## Installation

Install the sms-logpaser gem:

```bash
$ gem install sms-logparser
```

## Setup

Create the database table to track which logs have been parsed:

```bash
$ sms-logparser setup
```

Make a test run:

```bash
$ sms-logparser parse --simulate --verbose
```

## Usage

See available commands:

```bash
$ sms-logparser help
```

Parse logs from database and send them to the API

```bash
$ sms-logparser parse
```

Show the last parser runs:

```bash
$ sms-logparser history
```

## Configuration file

sms-logparser tries to read default options from a yaml file named '.sms-logparser.yml' placed in your home directory. Using the "-c/--config" flag you can adapt the path to the configuration file.

An example configuration (~/.sms-logparser.yml) for adapting the default MySQL password and setting the api_key:

```yaml
:mysql_password: 'my!secret'
:api_key:        'xqugl-hjh54-dr97-9kjdkjwi988d-123456'
```

## Development

  - check out the git repo (`git clone <repo>`)
  - implement your changes
  - run the tests (`rake test`)
  - bump the version number commit your changes and release a new version of the gem (`rake release`)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
