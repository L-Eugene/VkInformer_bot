# frozen_string_literal: true

# Migrate #3
class RemoveWallId < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :walls, :wall_id, :string
  end

  def self.down
    add_column :walls, :wall_id, :string
  end
end
