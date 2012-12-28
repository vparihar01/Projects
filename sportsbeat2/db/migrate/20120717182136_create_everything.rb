class CreateEverything < ActiveRecord::Migration
  def change
    ### PARTIAL REGISTRATIONS
    create_table :partial_registrations do |t|
      t.string :email, :null => false
      t.string :first_name
      t.string :last_name
      t.boolean :reminder_sent, :null => false, :default => false

      t.timestamps
    end

    add_index :partial_registrations, [:email], :unique => true

    ### USERS
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      t.string :profile_picture
      t.string :first_name
      t.string :last_name
      t.string :gender, :null => false
      t.date :birthdate, :null => false, :default => '1970-01-01'
      t.boolean :profile_completed, :default => false, :null => false
      t.integer :facebook_id, :limit => 8

      t.timestamps
    end

    add_index :users, :facebook_id, :unique => true
    add_index :users, :email, :unique => true
    # add_index :users, :reset_password_token, :unique => true
    # add_index :users, :confirmation_token, :unique => true

    ### ROLES
    create_table :roles do |t|
      t.string :name, :null => false
    end

    add_index :roles, :name, :unique => true

    create_table :roles_users, :id => false do |t|
      t.integer :role_id, :null => false
      t.integer :user_id, :null => false
    end

    add_index :roles_users, [:role_id, :user_id], :unique => true

    ### SUPPORT CONTACT MESSAGES
    create_table :support_contacts do |t|
      t.integer :user_id
      t.string :email
      t.string :kind, :null => false
      t.boolean :handled, :null => false, :default => false
      t.integer :handler_id
      t.datetime :handled_at
      t.text :text, :null => false
    end

    ### SCHOOLS
    create_table :schools do |t|
      t.string :name, :null => false
      t.string :address, :null => false
      t.string :city, :null => false
      t.string :county, :null => false
      t.string :state, :null => false
      t.string :zip, :null => false
      t.string :mascot
      t.string :primary_color
      t.string :secondary_color
      t.decimal :latitude, :null => false, :precision => 10, :scale => 7
      t.decimal :longitude, :null => false, :precision => 10, :scale => 7
      t.string :timezone, :null => false
      t.timestamps
    end

    ### SPORTS
    create_table :sports do |t|
      t.string :name, :unique => true, :null => false
      t.string :gender_code, :null => false
      t.string :profile_picture_url
      t.timestamps
    end

    ### POSITIONS
    create_table :positions do |t|
      t.integer :sport_id, :null => false
      t.string :name, :null => false
      t.string :abbrev
      t.timestamps
    end

    ### TEAMS
    create_table :teams do |t|
      t.integer :school_id, :null => false
      t.integer :sport_id, :null => false
      t.string  :level, :null => false
      t.string  :gender, :null => false
      t.timestamps
    end

    add_index :teams, [:school_id, :sport_id, :level, :gender], :unique => true

    ### GAMES
    create_table :games, :force => true do |t|
      t.integer :winner_id
      t.integer :winner_score
      t.integer :loser_id
      t.integer :loser_score
      t.integer :home_team_id, :null => false
      t.integer :home_team_score
      t.integer :away_team_id, :null => false
      t.integer :away_team_score
      t.datetime :datetime, :null => false
      t.integer :season_id, :null => false
      t.timestamps
    end

    add_index :games, [:home_team_id, :away_team_id, :datetime], :unique => true

    create_table :game_teams do |t|
      t.integer :game_id, :null => false
      t.integer :team_id, :null => false
      t.boolean :home, :null => false
      t.timestamps
    end

    add_index :game_teams, [:game_id, :team_id], :unique => true
    add_index :game_teams, [:game_id, :home], :unique => true

    ### SCORES
    create_table :scores do |t|
      t.integer :user_id, :null => false
      t.integer :game_id, :null => false
      t.integer :home_team_score, :null => false
      t.integer :away_team_score, :null => false
      t.timestamps
    end

    add_index :scores, [:game_id, :user_id], :unique => true

    ### ATHLETES
    create_table :athletes do |t|
      t.integer :user_id
      t.string :first_name
      t.string :last_name
      t.string :display_name
      t.integer :school_id, :null => false
      t.integer :final_year, :null => false
      t.integer :number
    end

    add_index :athletes, :user_id
    add_index :athletes, :school_id

    create_table :athlete_teams do |t|
      t.integer :athlete_id, :null => false
      t.integer :team_id, :null => false
      t.integer :season_id, :null => false
      t.boolean :active, :null => false, :default => false
    end

    add_index :athlete_teams, [:athlete_id, :team_id, :season_id]

    create_table :athlete_teams_positions, :id => false do |t|
      t.integer :athlete_team_id, :null => false
      t.integer :position_id, :null => false
    end

    ### CONVERSATIONS
    create_table :conversations do |t|
      t.integer :author_id, :null => false
      t.timestamps
    end

    add_index :conversations, :author_id

    create_table :conversation_visibilities do |t|
      t.integer :conversation_id, :null => false
      t.integer :user_id, :null => false
      t.integer :participants, :null => false
      t.boolean :unread, :null => false, :default => true
      t.boolean :hidden, :null => false, :default => false
      t.timestamps
    end

    add_index :conversation_visibilities, [:conversation_id, :user_id], :unique => true
    add_index :conversation_visibilities, [:user_id]

    create_table :conversation_messages do |t|
      t.integer :conversation_id, :null => false
      t.integer :author_id, :null => false
      t.text :text, :null => false
      t.timestamps
    end

    add_index :conversation_messages, [:conversation_id]

    ### POSTS
    create_table :posts do |t|
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
      t.datetime :edited_at
      t.integer :actor_id, :null => false
      t.string :actor_type, :null => false
      t.string :actor_display_name, :null => false
      t.integer :subject_id, :null => false
      t.string :subject_type, :null => false
      t.string :subject_display_name, :null => false
      t.integer :activity_id
      t.string :activity_type
      t.boolean :shared, :null => false, :default => false
      t.boolean :proxy_comments, :null => false, :default => false
      t.boolean :proxy_likes, :null => false, :default => false
      t.text :content, :null => false
      t.text :content_html, :null => false
      t.integer :comments_count, :null => false, :default => 0
    end

    ### COMMENTS
    create_table :comments do |t|
      t.integer :author_id, :null => false
      t.string :commentable_type, :null => false
      t.integer :commentable_id, :null => false
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :edited_at
      t.text :content, :null => false
      t.text :content_html, :null => false
    end

    add_index :comments, [:commentable_type, :commentable_id]

    ### FEEDS
    create_table :feed_entries do |t|
      t.string :owner, :null => false
      t.string :name, :null => false
      t.integer :post_id, :null => false
      t.boolean :hidden, :null => false, :default => false
      t.string :iso8601, :null => false, :length => 30
    end

    add_index :feed_entries, [
      :owner, :name, :post_id, :hidden, :iso8601
    ], {
      :unique => true,
      :name => "idx_feed_entries"
    }

    ### GALLERIES
    create_table :galleries do |t|
      t.integer :creator_id, :null => false
      t.integer :owner_id, :null => false
      t.string :owner_type, :null => false
      t.string :name, :null => false
      t.integer :thumbnail_id
      t.timestamps
    end

    add_index :galleries, [:owner_type, :owner_id]

    ### PICTURES
    create_table :pictures do |t|
      t.integer :owner_id, :null => false
      t.integer :gallery_id, :null => false
      t.string :file, :null => false
      t.string :caption
      t.integer :comments_count, :null => false, :default => 0
      t.timestamps
    end

    add_index :pictures, :gallery_id

    ### VIDEOS
    create_table :videos do |t|
      t.integer :owner_id, :null => false
      t.string :file, :null => false
      t.string :caption
      t.integer :comments_count, :null => false, :default => 0
      t.integer :zencoder_output_id
      t.integer :zencoder_job_id
      t.boolean :processed, :null => false, :default => false
      t.timestamps
    end

    ### SUBSCRIPTIONS
    create_table :subscriptions do |t|
      t.integer :subscriber_id, :null => false
      t.integer :subscribable_id, :null => false
      t.string :subscribable_type, :null => false
    end

    add_index :subscriptions, [
      :subscriber_id, :subscribable_id, :subscribable_type
    ], {
      :unique => true,
      :name => "idx_subscriptions"
    }

    ### LIKES
    create_table :likes do |t|
      t.integer :user_id, :null => false
      t.integer :likable_id, :null => false
      t.string :likable_type, :null => false
      t.timestamps
    end

    ### CONTESTS
    create_table :contests do |t|
      t.string :type, :null => false
      t.string :name, :null => false
      t.text :html_banner
      t.text :description
      t.text :term
      t.boolean :published, :null => false, :default => false
      t.binary :criteria_blob

      t.datetime :start
      t.datetime :end
      t.datetime :entry_deadline
    end

    create_table :contest_users do |t|
      t.integer :contest_id, :null => false
      t.integer :user_id, :null => false
      t.boolean :eligible, :null => false, :default => false
      t.boolean :participated, :null => false, :default => false
    end

    add_index :contest_users, [:contest_id, :user_id]

    create_table :picture_contest_entries do |t|
      t.integer :picture_contest_id, :null => false
      t.integer :picture_id, :null => false
      t.timestamps
    end

    add_index :picture_contest_entries, [
      :picture_contest_id, :picture_id
    ], {
      :unique => true,
      :name => :idx_picture_contest_entries
    }

    create_table :signup_contest_schools do |t|
      t.integer :signup_contest_id, :null => false
      t.integer :school_id, :null => false
      t.timestamps
    end

    add_index :signup_contest_schools, [
      :signup_contest_id, :school_id
    ], {
      :unique => true,
      :name => :idx_signup_contest_schools
    }

    ### SCORE ACTIONS
    create_table :score_actions do |t|
      t.integer :value, :null => false
      t.string :name, :unique => true, :null => false
      t.string :description
      t.string :href
    end
    add_index :score_actions, [:name, :value], :unique => true

    create_table :monthly_scores do |t|
      t.integer :user_id, :null => false
      t.integer :year, :null => false
      t.integer :month, :null => false
      t.integer :value, :null => false, :default => 0
    end
    add_index :monthly_scores, [:user_id, :year, :month, :value], :unique => true

    create_table :user_scores do |t|
      t.integer :user_id, :null => false
      t.integer :score_action_id, :null => false
      t.boolean :pending, :null => false, :default => true
      t.integer :value, :null => false
      t.datetime :created_at, :null => false
    end
    add_index :user_scores, [:user_id, :score_action_id]
    add_index :user_scores, [:user_id, :pending]

  end
end
