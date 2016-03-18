require 'sequel'
require 'sequel/connection_pool/threaded'
require 'yaml'
require 'pact_broker/logging'
require 'erb'
require 'pact_broker/project_root'

module DB
  include PactBroker::Logging
  ##
  # Sequel by default does not test connections in its connection pool before
  # handing them to a client. To enable connection testing you need to load the
  # "connection_validator" extension like below. The connection validator
  # extension is configurable, by default it only checks connections once per
  # hour:
  #
  # http://sequel.rubyforge.org/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
  #
  # Because most of our applications so far are accessed infrequently, there is
  # very little overhead in checking each connection when it is requested. This
  # takes care of stale connections.
  #
  # A gotcha here is that it is not enough to enable the "connection_validator"
  # extension, we also need to specify that we want to use the threaded connection
  # pool, as noted in the documentation for the extension.
  #
  def self.connect db_credentials
    con = Sequel.connect(db_credentials.merge(:logger => logger, :pool_class => Sequel::ThreadedConnectionPool, :encoding => 'utf8'))
    con.extension(:connection_validator)
    con.pool.connection_validation_timeout = -1 #Check the connection on every request
    con.timezone = :utc
    con
  end

  def self.connection_for_env env
    logger.info "Connecting to #{env} database."
    connect configuration_for_env(env)
  end

  def self.configuration_for_env env
    database_yml = PactBroker.project_root.join('config','database.yml')
    config = YAML.load(ERB.new(File.read(database_yml)).result)
    config.fetch(env)
  end

  PACT_BROKER_DB ||= connection_for_env ENV.fetch('RACK_ENV')

  def self.health_check
    PACT_BROKER_DB.synchronize do |c| c
      PACT_BROKER_DB.valid_connection? c
    end
  end
end
