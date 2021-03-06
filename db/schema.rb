# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150224131027) do

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body"
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"

  create_table "deleted_entries", force: :cascade do |t|
    t.integer  "feed_id",    null: false
    t.text     "guid",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "deleted_entries", ["guid", "feed_id"], name: "index_deleted_entries_on_guid_feed_id"

  create_table "entries", force: :cascade do |t|
    t.text     "title",                       null: false
    t.text     "url",                         null: false
    t.text     "author"
    t.text     "content",    limit: 16777215
    t.text     "summary",    limit: 16777215
    t.datetime "published",                   null: false
    t.text     "guid",                        null: false
    t.integer  "feed_id",                     null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "entries", ["feed_id"], name: "index_entries_on_feed_id"
  add_index "entries", ["guid", "feed_id"], name: "index_entries_on_guid_feed_id"
  add_index "entries", ["published", "created_at", "id"], name: "index_entries_on_published_created_at_id"

  create_table "entry_states", force: :cascade do |t|
    t.boolean  "read",       default: false, null: false
    t.integer  "user_id",                    null: false
    t.integer  "entry_id",                   null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "entry_states", ["entry_id", "user_id"], name: "index_entry_states_on_entry_id_user_id"
  add_index "entry_states", ["entry_id"], name: "index_entry_states_on_entry_id"
  add_index "entry_states", ["read", "user_id"], name: "index_entry_states_on_read_user_id"
  add_index "entry_states", ["user_id"], name: "index_entry_states_on_user_id"

  create_table "feed_subscriptions", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.integer  "feed_id",                    null: false
    t.integer  "unread_entries", default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "feed_subscriptions", ["feed_id", "user_id"], name: "index_feed_subscriptions_on_feed_id_user_id"
  add_index "feed_subscriptions", ["feed_id"], name: "index_feed_subscriptions_on_feed_id"
  add_index "feed_subscriptions", ["user_id", "unread_entries"], name: "index_feed_subscriptions_on_user_id_unread_entries"
  add_index "feed_subscriptions", ["user_id"], name: "index_feed_subscriptions_on_user_id"

  create_table "feeds", force: :cascade do |t|
    t.text     "title",                              null: false
    t.text     "url"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.text     "fetch_url",                          null: false
    t.datetime "last_fetched"
    t.integer  "fetch_interval_secs", default: 3600, null: false
    t.datetime "failing_since"
    t.boolean  "available",           default: true, null: false
  end

  add_index "feeds", ["available"], name: "index_feeds_on_available"
  add_index "feeds", ["fetch_url"], name: "index_feeds_on_fetch_url"
  add_index "feeds", ["title"], name: "index_feeds_on_title"
  add_index "feeds", ["url"], name: "index_feeds_on_url"

  create_table "feeds_folders", force: :cascade do |t|
    t.integer  "feed_id",    null: false
    t.integer  "folder_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "feeds_folders", ["feed_id"], name: "index_feeds_folders_on_feed_id"
  add_index "feeds_folders", ["folder_id"], name: "index_feeds_folders_on_folder_id"

  create_table "folders", force: :cascade do |t|
    t.integer  "user_id",                  null: false
    t.text     "title",                    null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.datetime "subscriptions_updated_at"
  end

  add_index "folders", ["user_id", "title"], name: "index_folders_on_user_id_title"
  add_index "folders", ["user_id"], name: "index_folders_on_user_id"

  create_table "opml_export_job_states", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.text     "state",                      null: false
    t.boolean  "show_alert",  default: true, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "filename"
    t.datetime "export_date"
  end

  add_index "opml_export_job_states", ["user_id"], name: "index_opml_export_job_states_on_user_id"

  create_table "opml_import_failures", force: :cascade do |t|
    t.integer  "opml_import_job_state_id", null: false
    t.text     "url",                      null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "opml_import_failures", ["opml_import_job_state_id"], name: "index_opml_import_failures_on_job_state_id"

  create_table "opml_import_job_states", force: :cascade do |t|
    t.integer  "user_id",                        null: false
    t.text     "state",                          null: false
    t.integer  "total_feeds",     default: 0,    null: false
    t.integer  "processed_feeds", default: 0,    null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "show_alert",      default: true, null: false
  end

  add_index "opml_import_job_states", ["user_id"], name: "index_opml_import_job_states_on_user_id"

  create_table "refresh_feed_job_states", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "feed_id",    null: false
    t.text     "state",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "refresh_feed_job_states", ["created_at"], name: "index_refresh_feed_job_states_on_created_at"
  add_index "refresh_feed_job_states", ["user_id"], name: "index_refresh_feed_job_states_on_user_id"

  create_table "subscribe_job_states", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.text     "state",      null: false
    t.text     "fetch_url",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "feed_id"
  end

  add_index "subscribe_job_states", ["created_at"], name: "index_subscribe_job_states_on_created_at"
  add_index "subscribe_job_states", ["user_id"], name: "index_subscribe_job_states_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                        limit: 255, default: "",    null: false
    t.string   "encrypted_password",           limit: 255, default: ""
    t.string   "reset_password_token",         limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                            default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",           limit: 255
    t.string   "last_sign_in_ip",              limit: 255
    t.string   "confirmation_token",           limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",            limit: 255
    t.integer  "failed_attempts",                          default: 0
    t.string   "unlock_token",                 limit: 255
    t.datetime "locked_at"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.boolean  "admin",                                    default: false, null: false
    t.text     "locale",                                                   null: false
    t.text     "timezone",                                                 null: false
    t.boolean  "quick_reading",                            default: false, null: false
    t.boolean  "open_all_entries",                         default: false, null: false
    t.text     "name",                                                     null: false
    t.string   "invitation_token",             limit: 255
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type",              limit: 255
    t.integer  "invitations_count",                        default: 0
    t.string   "unencrypted_invitation_token", limit: 255
    t.datetime "invitations_count_reset_at"
    t.boolean  "show_main_tour",                           default: true,  null: false
    t.boolean  "show_mobile_tour",                         default: true,  null: false
    t.boolean  "show_feed_tour",                           default: true,  null: false
    t.boolean  "show_entry_tour",                          default: true,  null: false
    t.datetime "subscriptions_updated_at"
    t.datetime "folders_updated_at"
    t.datetime "subscribe_jobs_updated_at"
    t.datetime "refresh_feed_jobs_updated_at"
    t.datetime "config_updated_at"
    t.datetime "user_data_updated_at"
    t.boolean  "free",                                     default: false, null: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["confirmed_at", "confirmation_sent_at"], name: "index_users_on_confirmation_fields"
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["invitation_limit"], name: "index_users_on_invitation_limit"
  add_index "users", ["invitation_token", "invitation_accepted_at", "invitation_sent_at"], name: "index_users_on_invitation_fields"
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true
  add_index "users", ["invitations_count", "invitations_count_reset_at"], name: "index_users_on_invitation_count_fields"
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count"
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true

end
