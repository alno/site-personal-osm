#!/usr/bin/env rake

namespace :db do

  desc "Migrate database schema"
  task :migrate do
    require 'lib/database'

    exec "bundle exec sequel -m db/migrate '#{DB_CONN_STRING}'"
  end

end

namespace :import do

  desc "Import data of zkir validator"
  task :zkir do
    require 'lib/database'
    require 'lib/importers/zkir'

    if ENV['FILE']
      Importers::Zkir.import! File.open(ENV['FILE'])
    else
      puts "You should specify an input file!"
    end
  end

end
