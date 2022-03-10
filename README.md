# PostgresKeyValue

[![Ruby](https://github.com/berkes/postgres_key_value/actions/workflows/main.yml/badge.svg)](https://github.com/berkes/postgres_key_value/actions/workflows/main.yml)

**Key-Value storage for Posgresql**

Performant and simple key-value storage in Posgresql. With a Hash-like
interface. Only dependency is pg gem.

PostgresKeyValue tries to get out of your way, by being unopiniated small, and
simple. 

PostgresKeyValue depends on the [pg gem](https://rubygems.org/gems/pg), but
doesn't add this as requirement, so that you can provide your own, your
version, fork or compatible gem instead.

Configuration and usage is done through dependency injection, which makes it
easy for you to test, and to replace with mocks. The design aims to decouple as
much as possible, allowing to integrate in the right place (and only there).

A few tools are included to prepare and optimize the database. Usable in e.g.
your migrations or a deploy script.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'postgres_key_value'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install postgres_key_value

## Usage

Steps are as follows:

1. Make a connection to a postgresql database.
2. Instantiate a PostgresKeyValue object by passing in this connection.
3. Write to-, and read from this database.

```ruby
require 'pg'
require 'postgres_key_value'

connection = PG::Connection.open(:dbname => 'test')
greetings = PostgresKeyValue::Store.new(connection) 

greetings[:en] = "Hello World"
greetings[:nl] = "Hallo Wereld"

greetings[:en]                          #=> Hello World
greetings['DE-de']                      #=> nil
greetings.fetch('DE-de', 'No greeting') #=> No greeting
greetings.key?(:nl)                     #=> true

# Can be another process on another machine entirely.
Thread.new do
  other_greetings = PostgresKeyValue::Store.new(connection) 
  other_greetings[:en] = "Hello Mars!"
end.join

greetings[:en]                          #=> Hello Mars!
```

## Technical details

Keys can only be strings or symbols. So be sure to convert your object to a 
string explicitely before using.

```ruby
greetings[nil]  #=> PostgresKeyValue::InvalidKey
greetings[42]   #=> PostgresKeyValue::InvalidKey
greetings['']   #=> nil
greetings['42'] #=> nil

```

TODO

* transactions
* indexes
* hstore
* connection pools
* read/write copies

Database is configured to store key/value in two columns: key is primary key,
value of type json. Primary is of type string, so PG limitation on keys and string
storage apply.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/berkes/postgres_key_value. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [code of conduct](https://github.com/berkes/postgres_key_value/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PostgresKeyValue project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/berkes/postgres_key_value/blob/master/CODE_OF_CONDUCT.md).
