# frozen_string_literal: true

require_relative 'vk_informer_bot'

begin
  require 'rspec/core/rake_task'
rescue LoadError
  puts 'No rspec found'
else
  RSpec::Core::RakeTask.new
end

begin
  require 'rubocop/rake_task'
rescue LoadError
  puts 'No rubocop found'
else
  RuboCop::RakeTask.new
end

import 'lib/rake/db.rake'

task default: ['rubocop', 'vk:db:migrate', 'spec']
