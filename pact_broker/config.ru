require 'fileutils'
require 'logger'
require 'sequel'
require 'sequel/connection_pool/threaded'
require 'pact_broker'
require 'delegate'
require 'rack/ssl-enforcer'

class DatabaseLogger < SimpleDelegator
  def info *args
    __getobj__().debug(*args)
  end
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      Sequel::DATABASES.each { |db| db.disconnect }
    end
  end
end

DATABASE_CREDENTIALS = {
  adapter: "postgres",
  user: ENV['PACT_BROKER_DATABASE_USERNAME'],
  password: ENV['PACT_BROKER_DATABASE_PASSWORD'],
  host: ENV['PACT_BROKER_DATABASE_HOST'],
  database: ENV['PACT_BROKER_DATABASE_NAME']
}

require './lib/validations'
require './lib/conf'
require './lib/rack-oauth2-bearer_checker'
require './lib/rack-oauth2-bearer_helpers'
require './lib/rack-attack_setup'

# require 'new_relic/rack'
# require 'new_relic/rack/agent_hooks'
# require 'new_relic/rack/error_collector'
# use NewRelic::Rack::AgentHooks
# use NewRelic::Rack::ErrorCollector
# NewRelic::Agent.manual_start

unless ENV['SKIP_HTTPS_ENFORCER'] == 'true'
  use Rack::SslEnforcer, :except => [Conf::HEART_BEAT_REGEX]
end

use Rack::Attack
use Rack::OAuth2::Bearer::Checker

app = PactBroker::App.new do | config |
  config.log_dir = "./"
  config.logger = ::Logger.new($stdout)
  config.logger.level = Logger::INFO

  config.auto_migrate_db = true
  config.use_hal_browser = true

  # Ref: https://github.com/bethesque/pact_broker/issues/39#issuecomment-154220511
  sequel_conf = {
    logger: DatabaseLogger.new(config.logger),
    encoding: 'utf8',
    pool_class: Sequel::ThreadedConnectionPool
  }
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(sequel_conf))

  # test connections in its connection pool before handing them to a client
  config.database_connection.extension(:connection_validator)

  # -1 means that connections will be validated every time, which avoids
  # 3600 is 1 hour as it is in seconds
  # errors when databases are restarted and connections are killed
  # has a performance penalty, so increase if the service is accessed freq
  config.database_connection.pool.connection_validation_timeout = 3600
end

run app
