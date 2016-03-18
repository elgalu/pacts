require 'sequel'
require 'pact_broker/db/validate_encoding'

Sequel.datetime_class = DateTime

module PactBroker
  module DB

    MIGRATIONS_DIR = File.expand_path("../../../db/migrations", __FILE__)

    def self.connection= connection
      @connection = connection
    end

    def self.connection
      @connection
    end

    def self.run_migrations database_connection
      Sequel.extension :migration
      Sequel::Migrator.run(database_connection, PactBroker::DB::MIGRATIONS_DIR)
    end

    def self.validate_connection_config
      PactBroker::DB::ValidateEncoding.(connection)
    end
  end
end
