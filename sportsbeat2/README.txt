This file will be updated as requirements change

This is the SportsBeat server software stack:

Ubuntu 12.04 LTS

Ruby 1.9.3-p194 - This is not available in the 12.04 package repository, so
you will have to install it if you have not already. rbenv or rvm is
convenient.

MySQL, from Ubuntu packages

Redis 2.6.0-rc6 - Currently Redis isn't used in many places but over time
that is expected to change. Currently redis is used to implement the
thumbs-up/likes feature. It is probably not necessary to setup redis right
away unless your work involves that feature.

Elasticsearch 0.19.2 - requires java to run

For both redis and elasticsearch, you can arrange to run the daemons in
whatever way you like, as long as the services are listening on their default
ports. That said, we use runit. We can provide you with the runit scripts
if you like.

To install all the gems necessary for this project, you should also install
the following ubuntu packages:

libmysqlclient-dev
libxml2-dev
libxslt1-dev

Database Setup

As indicated in the database.yml file, you should create a local database
named "sportsbeat2" that is accessible by the user "sportsbeat2" without a
password.

Seed data is provided, see the seed_* scripts in the db/ directory.

Three example users are guaranteed to exist:
admin@sportsbeat.com
john@sportsbeat.com
jane@sportsbeat.com

The seed files generate 1000 other users. All example users use the
password "password"

Important Note about Migrations

As you can see, at the moment, there's one big migration. It is an accumulation
of 73 previous migrations. For the moment, while this codebase is not in
producion, edits can and should be made to that migration file.

In the future, of course that will not be possible. In that case, it is very
important to note that migrations must be written in such a way that is
compatible with Rails' threadsafe mode. The reason for this is that we may
move to a threaded server in the future. Threadsafe mode may very well be the
default in the next major version of Rails.

For migrations, the most important difference in threadsafe mode is that
classes are not autoloaded. So if you want to write a migration that utilizes
a model, it will be preferable to write stub models within the migration:

class DoSomeMigration < ActiveRecord::Migration
  class User < ActiveRecord::Base
    belongs_to :some_association
  end

  def change
  ...
  end
end

Additionally, writing migrations this way will insulate the migration from
changes in the actual model class that might interfere.

Note about our JSON API

To emit JSON, we use a gem called roar, which provides a structured way
to generate JSON representations in a particular format (HAL). The relevant
files are stored in app/representers. Please use and implement representers.
Do not hand-roll JSON without checking with us.

Note about Zencoder and other callback-based APIs

To inform us about completed transcoding jobs, zencoder does an HTTP POST to
a specified callback URL. This makes testing zencoder difficult on a local
server.

If at all possible you should set up your own server to test on and create
an appropriate environment in config/environments. Don't forget to modify
initializers, database.yml and facebook.yml. 

Another possibility is the use of localhost tunneling service. Here are
some examples (I have no first hand experience with any of them)

  http://pagekite.net/
  http://progrium.com/localtunnel/
  https://showoff.io/
  http://pairkit.com/
  http://tunnlr.com/