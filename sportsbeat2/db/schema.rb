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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120717182136) do

  create_table "athlete_teams", :force => true do |t|
    t.integer "athlete_id",                    :null => false
    t.integer "team_id",                       :null => false
    t.integer "season_id",                     :null => false
    t.boolean "active",     :default => false, :null => false
  end

  add_index "athlete_teams", ["athlete_id", "team_id", "season_id"], :name => "index_athlete_teams_on_athlete_id_and_team_id_and_season_id"

  create_table "athlete_teams_positions", :id => false, :force => true do |t|
    t.integer "athlete_team_id", :null => false
    t.integer "position_id",     :null => false
  end

  create_table "athletes", :force => true do |t|
    t.integer "user_id"
    t.string  "first_name"
    t.string  "last_name"
    t.string  "display_name"
    t.integer "school_id",    :null => false
    t.integer "final_year",   :null => false
    t.integer "number"
  end

  add_index "athletes", ["school_id"], :name => "index_athletes_on_school_id"
  add_index "athletes", ["user_id"], :name => "index_athletes_on_user_id"

  create_table "comments", :force => true do |t|
    t.integer  "author_id",        :null => false
    t.string   "commentable_type", :null => false
    t.integer  "commentable_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "edited_at"
    t.text     "content",          :null => false
    t.text     "content_html",     :null => false
  end

  add_index "comments", ["commentable_type", "commentable_id"], :name => "index_comments_on_commentable_type_and_commentable_id"

  create_table "contest_users", :force => true do |t|
    t.integer "contest_id",                      :null => false
    t.integer "user_id",                         :null => false
    t.boolean "eligible",     :default => false, :null => false
    t.boolean "participated", :default => false, :null => false
  end

  add_index "contest_users", ["contest_id", "user_id"], :name => "index_contest_users_on_contest_id_and_user_id"

  create_table "contests", :force => true do |t|
    t.string   "type",                              :null => false
    t.string   "name",                              :null => false
    t.text     "html_banner"
    t.text     "description"
    t.text     "term"
    t.boolean  "published",      :default => false, :null => false
    t.binary   "criteria_blob"
    t.datetime "start"
    t.datetime "end"
    t.datetime "entry_deadline"
  end

  create_table "conversation_messages", :force => true do |t|
    t.integer  "conversation_id", :null => false
    t.integer  "author_id",       :null => false
    t.text     "text",            :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "conversation_messages", ["conversation_id"], :name => "index_conversation_messages_on_conversation_id"

  create_table "conversation_visibilities", :force => true do |t|
    t.integer  "conversation_id",                    :null => false
    t.integer  "user_id",                            :null => false
    t.integer  "participants",                       :null => false
    t.boolean  "unread",          :default => true,  :null => false
    t.boolean  "hidden",          :default => false, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "conversation_visibilities", ["conversation_id", "user_id"], :name => "index_conversation_visibilities_on_conversation_id_and_user_id", :unique => true
  add_index "conversation_visibilities", ["user_id"], :name => "index_conversation_visibilities_on_user_id"

  create_table "conversations", :force => true do |t|
    t.integer  "author_id",  :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "conversations", ["author_id"], :name => "index_conversations_on_author_id"

  create_table "feed_entries", :force => true do |t|
    t.string  "owner",                      :null => false
    t.string  "name",                       :null => false
    t.integer "post_id",                    :null => false
    t.boolean "hidden",  :default => false, :null => false
    t.string  "iso8601",                    :null => false
  end

  add_index "feed_entries", ["owner", "name", "post_id", "hidden", "iso8601"], :name => "idx_feed_entries", :unique => true

  create_table "galleries", :force => true do |t|
    t.integer  "creator_id",   :null => false
    t.integer  "owner_id",     :null => false
    t.string   "owner_type",   :null => false
    t.string   "name",         :null => false
    t.integer  "thumbnail_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "galleries", ["owner_type", "owner_id"], :name => "index_galleries_on_owner_type_and_owner_id"

  create_table "game_teams", :force => true do |t|
    t.integer  "game_id",    :null => false
    t.integer  "team_id",    :null => false
    t.boolean  "home",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "game_teams", ["game_id", "home"], :name => "index_game_teams_on_game_id_and_home", :unique => true
  add_index "game_teams", ["game_id", "team_id"], :name => "index_game_teams_on_game_id_and_team_id", :unique => true

  create_table "games", :force => true do |t|
    t.integer  "winner_id"
    t.integer  "winner_score"
    t.integer  "loser_id"
    t.integer  "loser_score"
    t.integer  "home_team_id",    :null => false
    t.integer  "home_team_score"
    t.integer  "away_team_id",    :null => false
    t.integer  "away_team_score"
    t.datetime "datetime",        :null => false
    t.integer  "season_id",       :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "games", ["home_team_id", "away_team_id", "datetime"], :name => "index_games_on_home_team_id_and_away_team_id_and_datetime", :unique => true

  create_table "likes", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.integer  "likable_id",   :null => false
    t.string   "likable_type", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "monthly_scores", :force => true do |t|
    t.integer "user_id",                :null => false
    t.integer "year",                   :null => false
    t.integer "month",                  :null => false
    t.integer "value",   :default => 0, :null => false
  end

  add_index "monthly_scores", ["user_id", "year", "month", "value"], :name => "index_monthly_scores_on_user_id_and_year_and_month_and_value", :unique => true

  create_table "partial_registrations", :force => true do |t|
    t.string   "email",                            :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "reminder_sent", :default => false, :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "partial_registrations", ["email"], :name => "index_partial_registrations_on_email", :unique => true

  create_table "picture_contest_entries", :force => true do |t|
    t.integer  "picture_contest_id", :null => false
    t.integer  "picture_id",         :null => false
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "picture_contest_entries", ["picture_contest_id", "picture_id"], :name => "idx_picture_contest_entries", :unique => true

  create_table "pictures", :force => true do |t|
    t.integer  "owner_id",                      :null => false
    t.integer  "gallery_id",                    :null => false
    t.string   "file",                          :null => false
    t.string   "caption"
    t.integer  "comments_count", :default => 0, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "pictures", ["gallery_id"], :name => "index_pictures_on_gallery_id"

  create_table "positions", :force => true do |t|
    t.integer  "sport_id",   :null => false
    t.string   "name",       :null => false
    t.string   "abbrev"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "posts", :force => true do |t|
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.datetime "edited_at"
    t.integer  "actor_id",                                :null => false
    t.string   "actor_type",                              :null => false
    t.string   "actor_display_name",                      :null => false
    t.integer  "subject_id",                              :null => false
    t.string   "subject_type",                            :null => false
    t.string   "subject_display_name",                    :null => false
    t.integer  "activity_id"
    t.string   "activity_type"
    t.boolean  "shared",               :default => false, :null => false
    t.boolean  "proxy_comments",       :default => false, :null => false
    t.boolean  "proxy_likes",          :default => false, :null => false
    t.text     "content",                                 :null => false
    t.text     "content_html",                            :null => false
    t.integer  "comments_count",       :default => 0,     :null => false
  end

  create_table "roles", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "roles", ["name"], :name => "index_roles_on_name", :unique => true

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true

  create_table "schools", :force => true do |t|
    t.string   "name",                                           :null => false
    t.string   "address",                                        :null => false
    t.string   "city",                                           :null => false
    t.string   "county",                                         :null => false
    t.string   "state",                                          :null => false
    t.string   "zip",                                            :null => false
    t.string   "mascot"
    t.string   "primary_color"
    t.string   "secondary_color"
    t.decimal  "latitude",        :precision => 10, :scale => 7, :null => false
    t.decimal  "longitude",       :precision => 10, :scale => 7, :null => false
    t.string   "timezone",                                       :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
  end

  create_table "score_actions", :force => true do |t|
    t.integer "value",       :null => false
    t.string  "name",        :null => false
    t.string  "description"
    t.string  "href"
  end

  add_index "score_actions", ["name", "value"], :name => "index_score_actions_on_name_and_value", :unique => true

  create_table "scores", :force => true do |t|
    t.integer  "user_id",         :null => false
    t.integer  "game_id",         :null => false
    t.integer  "home_team_score", :null => false
    t.integer  "away_team_score", :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "scores", ["game_id", "user_id"], :name => "index_scores_on_game_id_and_user_id", :unique => true

  create_table "signup_contest_schools", :force => true do |t|
    t.integer  "signup_contest_id", :null => false
    t.integer  "school_id",         :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "signup_contest_schools", ["signup_contest_id", "school_id"], :name => "idx_signup_contest_schools", :unique => true

  create_table "sports", :force => true do |t|
    t.string   "name",                :null => false
    t.string   "gender_code",         :null => false
    t.string   "profile_picture_url"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "subscriptions", :force => true do |t|
    t.integer "subscriber_id",     :null => false
    t.integer "subscribable_id",   :null => false
    t.string  "subscribable_type", :null => false
  end

  add_index "subscriptions", ["subscriber_id", "subscribable_id", "subscribable_type"], :name => "idx_subscriptions", :unique => true

  create_table "support_contacts", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "kind",                          :null => false
    t.boolean  "handled",    :default => false, :null => false
    t.integer  "handler_id"
    t.datetime "handled_at"
    t.text     "text",                          :null => false
  end

  create_table "teams", :force => true do |t|
    t.integer  "school_id",  :null => false
    t.integer  "sport_id",   :null => false
    t.string   "level",      :null => false
    t.string   "gender",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "teams", ["school_id", "sport_id", "level", "gender"], :name => "index_teams_on_school_id_and_sport_id_and_level_and_gender", :unique => true

  create_table "user_scores", :force => true do |t|
    t.integer  "user_id",                           :null => false
    t.integer  "score_action_id",                   :null => false
    t.boolean  "pending",         :default => true, :null => false
    t.integer  "value",                             :null => false
    t.datetime "created_at",                        :null => false
  end

  add_index "user_scores", ["user_id", "pending"], :name => "index_user_scores_on_user_id_and_pending"
  add_index "user_scores", ["user_id", "score_action_id"], :name => "index_user_scores_on_user_id_and_score_action_id"

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",           :null => false
    t.string   "encrypted_password",                  :default => "",           :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "profile_picture"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender",                                                        :null => false
    t.date     "birthdate",                           :default => '1970-01-01', :null => false
    t.boolean  "profile_completed",                   :default => false,        :null => false
    t.integer  "facebook_id",            :limit => 8
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["facebook_id"], :name => "index_users_on_facebook_id", :unique => true

  create_table "videos", :force => true do |t|
    t.integer  "owner_id",                              :null => false
    t.string   "file",                                  :null => false
    t.string   "caption"
    t.integer  "comments_count",     :default => 0,     :null => false
    t.integer  "zencoder_output_id"
    t.integer  "zencoder_job_id"
    t.boolean  "processed",          :default => false, :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

end
