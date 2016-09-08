# frozen_string_literal: true
class AddSoftDeletionToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :deleted_at, :timestamp
  end
end
