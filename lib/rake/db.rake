# frozen_string_literal: true

namespace :vk do
  namespace :db do
    desc 'Migrate the database'
    task :migrate do
      ActiveRecord::Base.establish_connection Vk.cfg.options['database']
      ActiveRecord::Migrator.migrate('vk_informer_bot/db/', nil)
    end
  end
end
