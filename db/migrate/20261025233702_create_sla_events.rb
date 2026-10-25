class CreateSlaEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_events do |t|
      t.references :ticket, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :minutes_remaining, null: false
      t.string :note

      t.timestamps
    end
    add_index :sla_events, %i[ticket_id kind], unique: true
  end
end
