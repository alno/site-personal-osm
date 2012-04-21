require 'sequel'

DB_CONFIG_FILE = File.open(File.expand_path('../config/database.yml', File.dirname(__FILE__)))
DB_CONFIG = YAML.load(DB_CONFIG_FILE)[ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development']
DB_CONN_STRING = "postgres://#{DB_CONFIG['username']}:#{DB_CONFIG['password']}@#{DB_CONFIG['host']}/#{DB_CONFIG['database']}"

DB = Sequel.connect DB_CONN_STRING

Sequel.extension :pg_hstore
