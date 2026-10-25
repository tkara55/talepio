# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_25_233702) do
  create_table "agents", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_agents_on_email", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.string "author_type", null: false
    t.string "author_name", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_comments_on_ticket_id"
  end

  create_table "sla_events", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.string "kind", null: false
    t.integer "minutes_remaining", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id", "kind"], name: "index_sla_events_on_ticket_id_and_kind", unique: true
    t.index ["ticket_id"], name: "index_sla_events_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "subject", null: false
    t.text "description", null: false
    t.string "requester_name", null: false
    t.string "requester_email", null: false
    t.string "priority", default: "normal", null: false
    t.string "status", default: "new", null: false
    t.integer "assignee_id"
    t.string "token", null: false
    t.datetime "first_response_due_at", null: false
    t.datetime "first_responded_at"
    t.datetime "solved_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["status"], name: "index_tickets_on_status"
    t.index ["token"], name: "index_tickets_on_token", unique: true
  end

  add_foreign_key "comments", "tickets"
  add_foreign_key "sla_events", "tickets"
  add_foreign_key "tickets", "agents", column: "assignee_id"
end
