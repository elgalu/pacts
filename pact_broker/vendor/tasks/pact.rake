require 'pact/tasks'

Pact::VerificationTask.new(:dev) do | pact |
  pact.uri "../pact_broker-client/spec/pacts/pact_broker_client-pact_broker.json"
end

namespace :pact do
  task :prepare => ['db:set_test_env', 'db:prepare:test']
  task :verify => :prepare
  task 'verify:at' => :prepare
  task 'verify:dev' => :prepare
end
