# frozen_string_literal: true

require_relative 'vk_informer_bot.rb'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

import 'lib/rake/db.rake'

task default: ['rubocop', 'vk:db:migrate', 'spec']
