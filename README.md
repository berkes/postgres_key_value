# PostgresKeyValue

[![Ruby](https://github.com/berkes/postgres_key_value/actions/workflows/main.yml/badge.svg)](https://github.com/berkes/postgres_key_value/actions/workflows/main.yml)
[![Gem Version](https://badge.fury.io/rb/postgres_key_value.svg)](https://badge.fury.io/rb/postgres_key_value)
[![Maintainability](https://api.codeclimate.com/v1/badges/2315ea261cc094010c76/maintainability)](https://codeclimate.com/github/berkes/postgres_key_value/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/2315ea261cc094010c76/test_coverage)](https://codeclimate.com/github/berkes/postgres_key_value/test_coverage)

**Key-Value storage for Posgresql**

Performant and simple key-value storage in Posgresql. With a Hash-like
interface. Only dependency is pg gem.

PostgresKeyValue tries to get out of your way, by being unopiniated small, and
simple. 

It works similar, but not compatible to, Hash. Some features from Hash are implemented, others
deliberately omitted when they don't make sense or would make leaky abstractions.

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
* [x] Determine locking and transactional behaviour: who wins on a conflict?
* [x] Add proper index to key. Introduce some benchmark tests.
* [ ] Allow read-only setup so that e.g. workers can read but never write.
* [ ] Allow "connection" to be passed in from ActiveRecord (and sequel?) so that users can re-use it.
* [x] Add tools to use in migrations or deploy scripts to setup database like we do in tests.
* [x] Add `key?()` api to check if a key exists.
* [x] Add `fetch()` api to provide a default and/or raise exception similar to ENV and hash.
* [x] Add a default to initializer for the entire store. Maybe with a block, to mimic Hash.new signature?
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

We don't install pg gem for you as dependency, so ensure you add it yourself.
For example:

```ruby
gem 'pg'
```

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

```ruby
class CursorsKvPreparator
  include PostgresKeyValue::Utils
  DB_NAME = 'buttonshop_kv_store'
  TABLE_NAME = 'cursors'

  def initialize(connection)
    @table_name = table_name
    @connection = connection
  end

  def prepare
    MyInfra::Databases::CreateDatabaseCommand.new(DB_NAME)
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
* connection pools
* read/write copies

Database is configured to store key/value in two columns: key is primary key,
value of type json. Primary is of type string, so PG limitation on keys and string
storage apply.

PostgresKeyValue deliberately tries not to be fully compatible with Hash. But it 
does offer a similar interface. Mainly because such an opaque abstraction is leaky:

A table with KV storages can, by design, grow very large, whereas a hash is
memory bound. so features like iterators `store.each {|k,v| ... }` or
`store.to_a` require the underlying limits to leak through. We'd then need
logic, config, etc to handle when the database becomes too big for memory to hold.

We allow keys only to be strings, and not "anything" as hash does. The database
stores keys as strings, so if we'd allow "anything" as key, the marshalling or
serializing would not only become complex, it puts a performance hit on all
usage: so the ones using it with strings as keys would become slower too. 

The values are serialized using JSON. This is lossy. This is by-design, but for
security reasons. Marshalling code `object.marshall` retains the entire state,
including methods, or callbacks and allows the provider of data to even
monkeypatch your ruby codebase. We chose for JSON, as that is simplest, and
therefore secured from these attacks (unless JSON.parse is vulnarable, which is
not unthinkable).

Many methods on Hash don't make a lot of sense either. E.g. most methods that
operate on the entire hash, like `transform_keys!` or `compact` have little use
in a pure KV lookup system. When in need of such operations, you probably need
an actual database-table (which, not by coincidence, the `connection` already offers!)

Another reason for not wanting to have feature-parity with Hash, is that it
would grow this gem far beyond "simple", without there being a clear need for
all the added features. Hash is really large! Rather, if there are features you need, raise an issue
(or write a patch) so we can determine if it fits the scope and is worth the
extra code.

The keys are indexed, this is default for Postgresql for primary keys, using
btree. This causes some slowdown on-insert but fast reads.
**In cases where you have a small dataset. and many writes but fewer reads,
this causes notable performance penalties**. Removing the index may help. But
only for small datasets, as the upsert-behaviour causes every write to perform 
a lookup anyway: on large datasets, writing will become slow without this index.

## Alternatives

Ruby core has Hash, and DBM. Redis is another alternative that may be better
suited too.

*PostgresKeyValue* is most helpful when:

* You are using Postgres for other storage already and want to avoid extra services (=complexity, cost, sysadmin)
* You have your service spread out over multiple servers OR
* You cannmot write files on disk
* Your KV database is too big to fit in memory

An in-memory database is -by far- the fastest and easiest. Just a `Hash.new`
and be done with it. Nothing beats this! Except when other processes, threads
or servers need to access it. A singelton-pattern with Hash might help,
but that comes with added complexity and potential race-conditions.

Storing the KV on disk is very easy too. Especially since [Ruby comes with
`DBM`](https://ruby-doc.org/stdlib-2.6.1/libdoc/dbm/rdoc/DBM.html) in its
stdlib. This is a dedicated key-value database stored in a file (berkely
database). Downside is that the speed of the disk matters (much, slower than
memory!) and that all services wanting to read and write need access to the
disk. Race-conditions and locking issues must be solved too in a setup where
multiple processes use one such database-file.

[Redis](https://developer.redis.com/develop/ruby/) is another obvious solution.
Depending on the network, this is often faster than the RDM on disk. But Redis
comes with its own swath of issues. Most of them are logical tradeoffs to keep
things fast and simple. But the biggest Downside is that it requires you to
manage (and/or pay for) an extra service, when you quite often have a postgres
at hand already. Other downsides are that redis isn't fully acid-complient. It
can be configured to write backups to disk, but it really isn't a good use-case
to store data that cannot be re-created. It's perfect for things like cache,
temporary tokens, or projections (which can be re-build from primary storage or
other services) but not very solid for data that doesn't live elsewhere, like a
queue with to-be-sent emails, events or commands: if the database crashes,
there's no way to re-send those emails, re-emit the events or re-schedule the
commands: the data is gone forever. Postgres has this solved with its WAL.

We have a benchmark, that compares Hash, RDM, Redis and PostgresKeyValue. You
can run it with `RUN_ALTERNATIVES_BENCHMARKS=true b rake benchmark`. 

It is clear that *PostgresKeyValue* is slowest. Especially when writing.

```
                     user     system      total        real
Write Hash       1.010123   0.000000   1.010123 (  1.010157)
Write DBM        9.648655   0.452455  10.101110 ( 10.104472)
Write Redis      4.492164   0.996256   5.488420 (  8.091726)
Write Postgres  17.056292   9.601811  26.658103 (293.735055)
Read Hash        0.227127   0.000000   0.227127 (  0.227968)
Read DBM        10.124688   0.118673  10.243361 ( 10.277904)
Read Redis       4.066872   1.013194   5.080066 (  7.109471)
Read Postgres    1.453755   0.966952   2.420707 (  9.943543)
```

This was run with postgresql and redis in a throttled (1 CPU - standard
settings) docker on localhost. So network overhead can be neglegted, but CPU is
a limiting factor. And writing to PostgresKeyValue database requires indexing,
which is CPU-heavy. This is also the reason why `real` time is so much higher
for postgres: the ruby side is waiting a lot for postgresql server to finish
writing.

(Please note that for this benchmark you need a redis server running and must
have compiled ruby with DBM support.)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

In order to run the comparison benchmark, which compares this gem to Ruby Hash,
YAML/DBM (both stdlib) and Redis, you need a ruby compiled with `dbm`, which is
the berkely DB installed. For Ubuntu, this means installing libdb-dev (`sudo
apt install libdb-dev `) and then recompiling ruby (`rbenv install --force` if
you use rbenv). And you need a redis server running.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/berkes/postgres_key_value. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [code of conduct](https://github.com/berkes/postgres_key_value/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PostgresKeyValue project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/berkes/postgres_key_value/blob/master/CODE_OF_CONDUCT.md).
