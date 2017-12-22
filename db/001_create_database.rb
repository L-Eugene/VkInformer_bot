# frozen_string_literal: true

# Migrate #1
class CreateDatabase < ActiveRecord::Migration
  def create_chats
    create_table :chats do |t|
      t.string :chat_id
      t.boolean :enabled
    end
  end

  def create_walls
    create_table :walls do |t|
      t.string :wall_id
      t.string :domain
      t.integer :last_message_id
    end
  end

  def create_links
    create_table :links do |t|
      t.belongs_to :chat, index: true
      t.belongs_to :wall, index: true
    end
  end

  def self.up
    create_chats
    create_walls
    create_links
  end

  def self.down
    drop_table :chats
    drop_table :walls
    drop_table :links
  end
end
