# frozen_string_literal: true

namespace :vk do
  namespace :token do
    desc 'Add vk token'
    task :add, [:token] do |_t, args|
      Vk::Token.new(key: args.token).save
      puts "#{args.token} added".green
    end

    desc 'Delete vk token'
    task :del, [:token] do |_t, args|
      begin
        Vk::Token.find_by(key: args.token).destroy
        puts "#{args.token} removed".green
      rescue NoMethodError
        puts 'No such token'.red
      end
    end

    desc 'Show token usage statistic'
    task :stat do
      Vk::Token.all.each do |token|
        puts "#{token.id}: #{token.today}"
      end
    end
  end
end
