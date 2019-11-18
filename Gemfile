# frozen_string_literal: true

unless respond_to? :resolve_gem
  def resolve_gem(*opts)
    gem(*opts)
  end
end

source 'https://rubygems.org' do
  resolve_gem 'activerecord'
  resolve_gem 'faraday'
  resolve_gem 'faraday_middleware'
  resolve_gem 'mysql2'
  resolve_gem 'r18n-core'
  resolve_gem 'r18n-rails-api'
  resolve_gem 'telegram-bot-ruby'
  resolve_gem 'terrapin'

  group :test do
    resolve_gem 'database_cleaner'
    resolve_gem 'factory_bot'
    resolve_gem 'rake'
    resolve_gem 'rspec'
    resolve_gem 'rubocop'
    resolve_gem 'sqlite3', '~> 1.4.0'
    resolve_gem 'webmock'
  end
end
