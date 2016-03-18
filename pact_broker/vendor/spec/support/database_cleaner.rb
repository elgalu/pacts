require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    if defined?(::DB)
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with :truncation
    end
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # config.before(:each) do
  #   DatabaseCleaner.start if defined?(::DB)
  # end

  # config.after(:each) do
  #   DatabaseCleaner.clean if defined?(::DB)
  # end
end
