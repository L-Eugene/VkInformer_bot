# frozen_string_literal: true

require_relative 'vk_informer_bot.rb'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'active_record'

include ActiveRecord::Tasks

DatabaseTasks.env = :development
DatabaseTasks.db_dir = './'
DatabaseTasks.migrations_paths = 'db'

DatabaseTasks.database_configuration = Vk.cfg.options['database']

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

task :environment do
  ActiveRecord::Base.establish_connection Vk.cfg.options['database']
end

load 'active_record/railties/databases.rake'

task default: ['rubocop', 'db:migrate', 'spec']
