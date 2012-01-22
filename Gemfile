source 'http://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem 'activesupport', '>= 2.3.5'

# Requirements for both clients and servers.
gem 'activesupport', '>= 3.2.0'
gem 'i18n', '>= 0.6.0' # For ActiveSupport
# Used by Serf::Messages::*
gem 'uuidtools', '>= 2.1.2'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  gem 'rspec', '~> 2.3.0'
  gem 'yard', '~> 0.6.0'
  gem 'bundler', '~> 1.0.0'
  gem 'jeweler', '~> 1.6.4'
  gem 'simplecov', '>= 0'

  # Soft Dependencies
  #gem 'log4r', '~> 1.1.9'
  gem 'msgpack', '>= 0.4.6'
  #gem 'multi_json', '~> 1.0.3'

  # For Server Side of things
  gem 'eventmachine', '>= 0.12.10'
end
