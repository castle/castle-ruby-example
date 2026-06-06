class CreateCastleWebhooks < ActiveRecord::Migration[5.2]
  def change
    create_table :integrations_castle_webhooks do |t|
      t.text :body, null: false, default: '{}'
      t.datetime :created_at, null: false
    end
  end
end
