# frozen_string_literal: true

namespace :vk do
  ActiveRecord::Base.establish_connection Vk.cfg.options['database']

  DatabaseTasks.db_dir = '.'
  DatabaseTasks.migrations_paths = Vk.cfg.options['basedir']

  load 'active_record/railties/databases.rake'
end
