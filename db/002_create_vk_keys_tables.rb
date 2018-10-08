# frozen_string_literal: true

# Migrate #2
class CreateVkKeysTables < ActiveRecord::Migration[4.2]
  def create_tokens
    create_table :tokens do |t|
      t.string :key
    end
  end

  def create_stats
    create_table :stats do |t|
      t.date :date
      t.integer :count

      t.belongs_to :token, index: true
    end
  end

  def self.up
    create_tokens
    create_stats
  end

  def self.down
    drop_table :tokens
    drop_table :stats
  end
end
