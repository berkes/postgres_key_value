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

## PostgresKeyValue is not finished!

Work in Progress. Here are some evident TODOs (will be moved into github issues later)

* [x] Fix glaring SQL injection holes. Use prepared statement or params to ensure clean input.
* [ ] Determine locking and transactional behaviour: who wins on a conflict?
* [x] Add proper index to key. Introduce some benchmark tests.
* [ ] Allow read-only setup so that e.g. workers can read but never write.
* [ ] Allow "connection" to be passed in from ActiveRecord (and sequel?) so that users can re-use it.
* [ ] Add tools to use in migrations or deploy scripts to setup database like we do in tests.
* [ ] Add `key?()` api to check if a key exists.
* [ ] Add `fetch()` api to provide a default and/or raise exception similar to ENV and hash.
* [ ] Add a default to initializer for the entire store. Maybe with a block, to mimic Hash.new signature?
* [ ] Add sanitizers and protection for the JSON de- serializers e.g. storage size or formats.
* [ ] Allow JSON de- serializers to be dependency-injected instead of using `JSON.parse` and `x.to_json`.
* [ ] Check for more robust SQL injection protection. e.g. by force-escaping before use? See: https://stackoverflow.com/a/42281333/73673
* [ ] Use prepared statement or params to improve performance.

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

## Utils

Utils to create and prepare the table are provided. For example in your migrations:

```ruby
class CreateKVTableForCursors < ButtonShop::Migration
  include PostgresKeyValue::Utils

  def migrate_up
    create_table('cursors', 'buttonshop_kv_store')
  end

  def migrate_down
    drop_table('cursors', 'buttonshop_kv_store')
  end

  private

  def connection
    ButtonShop.config.primary_db_connection
  end
end
```

And in a hypthetical deployment or provisioning tool

```
class CursorsKvPreparator
  include PostgresKeyValue::Utils
  DB_NAME = 'buttonshop_kv_store'
  TABLE_NAME = 'cursors'

  def initialize(connection)
    @table_name = table_name
    @connection = connection
  end

  def prepare
    create_database(DB_NAME)
    create_table(TABLE_NAME, DB_NAME)
  end

  private

  attr_reader :connection
end

on :staging_server do
  CursorsKvPreparator.new(@pg_connection).prepare
end
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

TODO: write about

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
