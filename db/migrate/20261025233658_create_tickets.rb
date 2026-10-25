class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :subject, null: false
      t.text :description, null: false
      t.string :requester_name, null: false
      t.string :requester_email, null: false
      t.string :priority, null: false, default: "normal"
      t.string :status, null: false, default: "new"
      t.references :assignee, null: true, foreign_key: { to_table: :agents }
      t.string :token, null: false
      t.datetime :first_response_due_at, null: false
      t.datetime :first_responded_at
      t.datetime :solved_at
      t.datetime :closed_at

      t.timestamps
    end
    add_index :tickets, :token, unique: true
    add_index :tickets, :status
  end
end
