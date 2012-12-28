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

ActiveRecord::Schema.define(:version => 20120515233229) do

  create_table "addresses", :force => true do |t|
    t.integer  "addressable_id"
    t.string   "name"
    t.string   "attention"
    t.string   "street"
    t.string   "suite"
    t.string   "city"
    t.integer  "postal_code_id"
    t.string   "addressable_type"
    t.boolean  "is_primary",       :default => false, :null => false
    t.integer  "country_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "proprietary_id"
  end

  create_table "assembly_assignments", :force => true do |t|
    t.integer  "assembly_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bisac_assignments", :force => true do |t|
    t.integer  "product_id"
    t.integer  "bisac_subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bisac_subjects", :force => true do |t|
    t.string  "code"
    t.string  "literal"
    t.integer "seq"
    t.string  "trans"
    t.text    "comments"
  end

  create_table "bundles_products", :id => false, :force => true do |t|
    t.integer "bundle_id"
    t.integer "product_id"
  end

  create_table "card_authorizations", :force => true do |t|
    t.integer "user_id"
    t.integer "line_item_collection_id"
    t.string  "transaction_id",          :limit => 20
    t.string  "first_name",              :limit => 30
    t.string  "last_name",               :limit => 30
    t.string  "number",                  :limit => 20
    t.integer "month"
    t.integer "year"
    t.string  "card_type",               :limit => 20
    t.string  "address1",                :limit => 80
    t.string  "city",                    :limit => 40
    t.string  "state",                   :limit => 20
    t.string  "zip",                     :limit => 20
    t.string  "country",                 :limit => 20
    t.decimal "amount",                                :precision => 6, :scale => 2, :default => 0.0
    t.boolean "captured"
  end

  create_table "catalog_requests", :force => true do |t|
    t.datetime "created_at"
    t.boolean  "is_processed", :default => false, :null => false
  end

  create_table "categories", :force => true do |t|
    t.string  "name"
    t.string  "proprietary_id", :limit => 16
    t.boolean "is_visible",                   :default => false
    t.string  "abbreviation",   :limit => 64
  end

  create_table "categories_products", :id => false, :force => true do |t|
    t.integer "category_id", :default => 0, :null => false
    t.integer "product_id",  :default => 0, :null => false
  end

  add_index "categories_products", ["product_id"], :name => "fk_cp_product"

  create_table "collections", :force => true do |t|
    t.string   "name"
    t.date     "released_on"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "available_products_counter",               :default => 0
    t.integer  "parent_id"
    t.string   "proprietary_id",             :limit => 16
  end

  create_table "contracts", :force => true do |t|
    t.date    "start_on"
    t.date    "end_on"
    t.float   "rate"
    t.integer "sales_team_id"
    t.integer "sales_zone_id"
    t.string  "category",      :default => "All"
  end

  create_table "contributor_assignments", :force => true do |t|
    t.integer "contributor_id",               :default => 0,   :null => false
    t.string  "role",           :limit => 64, :default => "0", :null => false
    t.integer "product_id",                   :default => 0,   :null => false
  end

  add_index "contributor_assignments", ["product_id"], :name => "fk_bp_product"
  add_index "contributor_assignments", ["role"], :name => "fk_bp_bio_category"

  create_table "contributors", :force => true do |t|
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",           :limit => 128, :default => "", :null => false
    t.text     "description",                                   :null => false
    t.string   "default_role",   :limit => 64
    t.string   "proprietary_id", :limit => 16
  end

  create_table "countries", :force => true do |t|
    t.string "name"
    t.string "iso_code_2"
    t.string "iso_code_3"
    t.string "fedex_code"
    t.string "ufsi_code"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "discounts", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.decimal  "amount",     :precision => 6, :scale => 2, :default => 0.0
    t.boolean  "percent"
    t.date     "start_on"
    t.date     "end_on"
    t.string   "type",                                     :default => "Coupon"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "downloads", :force => true do |t|
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "title",        :limit => 128
    t.string   "filename",     :limit => 128
    t.string   "description"
    t.integer  "views",                       :default => 0,    :null => false
    t.boolean  "is_visible",                  :default => true
    t.integer  "size"
    t.string   "content_type"
  end

  create_table "editorial_reviews", :force => true do |t|
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.date     "written_on"
    t.text     "body",                                          :null => false
    t.string   "source",         :limit => 128, :default => "", :null => false
    t.string   "author",         :limit => 128
    t.string   "proprietary_id", :limit => 16
    t.string   "title"
  end

  create_table "editorial_reviews_products", :id => false, :force => true do |t|
    t.integer "editorial_review_id", :default => 0, :null => false
    t.integer "product_id",          :default => 0, :null => false
  end

  add_index "editorial_reviews_products", ["product_id"], :name => "fk_ep_product"

  create_table "errata", :force => true do |t|
    t.integer  "product_format_id"
    t.string   "edition"
    t.string   "erratum_type"
    t.integer  "user_id"
    t.string   "name"
    t.string   "email"
    t.integer  "page_number"
    t.text     "description"
    t.string   "status",            :default => "Submitted"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "excerpts", :force => true do |t|
    t.integer  "title_id"
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "ipaper_id"
    t.string   "ipaper_access_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "faqs", :force => true do |t|
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.string   "question"
    t.text     "answer"
  end

  create_table "formats", :force => true do |t|
    t.string   "name"
    t.string   "form"
    t.string   "detail"
    t.boolean  "is_default"
    t.boolean  "is_pdf"
    t.boolean  "is_virtual"
    t.boolean  "is_processed"
    t.integer  "units",               :limit => 2, :default => 1,    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "requires_valid_isbn",              :default => true, :null => false
  end

  create_table "handouts", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "teaching_guide_id"
    t.string   "document"
    t.integer  "download_counter",  :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "handouts", ["teaching_guide_id"], :name => "index_handouts_on_teaching_guide_id"

  create_table "headlines", :force => true do |t|
    t.string   "title"
    t.text     "snippet"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "levels", :force => true do |t|
    t.string   "name"
    t.string   "abbreviation", :limit => 4
    t.boolean  "is_visible",                :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "line_item_collections", :force => true do |t|
    t.decimal  "amount",                         :precision => 11, :scale => 2, :default => 0.0
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                                                          :default => "Cart"
    t.string   "name"
    t.integer  "sales_team_id"
    t.string   "token"
    t.decimal  "shipping_amount",                :precision => 11, :scale => 2, :default => 0.0
    t.string   "shipping_method",   :limit => 2
    t.decimal  "weight",                         :precision => 6,  :scale => 2, :default => 0.0
    t.decimal  "tax",                            :precision => 11, :scale => 2, :default => 0.0
    t.string   "payment_method"
    t.text     "comments"
    t.datetime "completed_at"
    t.decimal  "processing_amount",              :precision => 11, :scale => 2, :default => 0.0
    t.string   "status"
    t.integer  "discount_id"
    t.decimal  "discount_amount",                :precision => 6,  :scale => 2, :default => 0.0
    t.string   "discount_code"
    t.decimal  "alsquiz_amount",                 :precision => 11, :scale => 2, :default => 0.0
    t.integer  "customer_id"
  end

  add_index "line_item_collections", ["token"], :name => "index_carts_on_token"

  create_table "line_items", :force => true do |t|
    t.integer "line_item_collection_id"
    t.integer "quantity",                                               :default => 0
    t.decimal "unit_amount",             :precision => 11, :scale => 2, :default => 0.0
    t.decimal "total_amount",            :precision => 11, :scale => 2, :default => 0.0
    t.boolean "saved_for_later"
    t.integer "product_format_id",                                                       :null => false
  end

  add_index "line_items", ["product_format_id"], :name => "index_line_items_on_product_format_id"

  create_table "links", :force => true do |t|
    t.string   "title",            :limit => 128
    t.text     "description"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.string   "url"
    t.boolean  "is_kids"
    t.boolean  "is_adults"
    t.boolean  "is_highlight"
    t.integer  "views",                           :default => 0, :null => false
    t.integer  "code"
    t.string   "redirect"
    t.string   "meta_title",       :limit => 128
    t.text     "meta_description"
    t.string   "proprietary_id",   :limit => 16
  end

  create_table "links_products", :id => false, :force => true do |t|
    t.integer "link_id",    :default => 0, :null => false
    t.integer "product_id", :default => 0, :null => false
  end

  add_index "links_products", ["product_id"], :name => "fk_lp_product"

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "path"
    t.string   "layout",       :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_protected",               :default => false, :null => false
  end

  add_index "pages", ["path"], :name => "index_pages_on_path", :unique => true

  create_table "postal_codes", :force => true do |t|
    t.string  "name"
    t.integer "zone_id"
    t.integer "sales_zone_id"
    t.decimal "tax_rate",      :precision => 6, :scale => 5, :default => 0.0
  end

  add_index "postal_codes", ["name"], :name => "index_postal_codes_on_name", :unique => true
  add_index "postal_codes", ["sales_zone_id"], :name => "index_postal_codes_on_sales_zone_id"
  add_index "postal_codes", ["zone_id"], :name => "index_postal_codes_on_zone_id"

  create_table "posted_transaction_lines", :force => true do |t|
    t.integer "posted_transaction_id"
    t.integer "product_id"
    t.integer "quantity"
    t.decimal "unit_amount",           :precision => 11, :scale => 2
    t.decimal "total_amount",          :precision => 11, :scale => 2
    t.decimal "rep_base",              :precision => 11, :scale => 2
  end

  add_index "posted_transaction_lines", ["product_id"], :name => "index_posted_transaction_lines_on_product_id"

  create_table "posted_transactions", :force => true do |t|
    t.string  "purchase_order"
    t.date    "posted_on"
    t.date    "shipped_on"
    t.date    "transacted_on"
    t.decimal "amount",             :precision => 11, :scale => 2
    t.decimal "ship_amount",        :precision => 11, :scale => 2
    t.decimal "ship_sale_amount",   :precision => 11, :scale => 2
    t.decimal "transaction_amount", :precision => 11, :scale => 2
    t.decimal "tax",                :precision => 11, :scale => 2
    t.decimal "rep_base",           :precision => 11, :scale => 2
    t.integer "sales_team_id"
    t.integer "customer_id"
    t.string  "type"
    t.integer "contract_id"
  end

  add_index "posted_transactions", ["customer_id"], :name => "index_posted_transactions_on_customer_id"

  create_table "preferences", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "owner_id",   :null => false
    t.string   "owner_type", :null => false
    t.integer  "group_id"
    t.string   "group_type"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["owner_id", "owner_type", "name", "group_id", "group_type"], :name => "index_preferences_on_owner_and_name_and_preference", :unique => true

  create_table "price_changes", :force => true do |t|
    t.integer  "product_format_id",                                                   :null => false
    t.decimal  "price_list",        :precision => 11, :scale => 2,                    :null => false
    t.decimal  "price",             :precision => 11, :scale => 2,                    :null => false
    t.date     "implement_on"
    t.string   "state",                                            :default => "new", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "price_changes", ["implement_on"], :name => "index_price_changes_on_implement_on"
  add_index "price_changes", ["state"], :name => "index_price_changes_on_state"

  create_table "product_downloads", :force => true do |t|
    t.string   "content_type"
    t.string   "filename"
    t.string   "thumbnail"
    t.integer  "size"
    t.integer  "parent_id"
    t.integer  "title_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_downloads_users", :id => false, :force => true do |t|
    t.integer "product_download_id"
    t.integer "user_id"
  end

  create_table "product_formats", :force => true do |t|
    t.integer  "product_id",                                                                 :null => false
    t.integer  "format_id",  :limit => 2
    t.decimal  "price_list",               :precision => 11, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "price",                    :precision => 11, :scale => 2, :default => 0.0,   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "isbn"
    t.string   "status",     :limit => 4,                                 :default => "NYP", :null => false
    t.decimal  "weight",                   :precision => 6,  :scale => 2, :default => 0.0
    t.string   "dimensions", :limit => 32
  end

  add_index "product_formats", ["isbn"], :name => "index_product_formats_on_isbn"
  add_index "product_formats", ["product_id", "format_id"], :name => "products_formats", :unique => true
  add_index "product_formats", ["product_id"], :name => "formats_by_products"

  create_table "products", :force => true do |t|
    t.string   "name"
    t.boolean  "is_book"
    t.boolean  "is_wholesale"
    t.text     "description"
    t.date     "available_on"
    t.integer  "reading_level_id"
    t.string   "type"
    t.integer  "copyright"
    t.string   "graphics",              :limit => 64
    t.integer  "pages"
    t.string   "dewey",                 :limit => 32
    t.string   "subtitle"
    t.string   "spotlight_description"
    t.string   "alsquiznr",             :limit => 8
    t.decimal  "alspoints",                            :precision => 3, :scale => 1
    t.decimal  "alsreadlevel",                         :precision => 3, :scale => 1
    t.string   "alsinterestlevel",      :limit => 32
    t.integer  "interest_level_min_id"
    t.integer  "interest_level_max_id"
    t.boolean  "is_taxable",                                                         :default => true
    t.string   "author",                :limit => 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "publisher",             :limit => 128
    t.string   "imprint",               :limit => 128
    t.text     "annotation"
    t.string   "language",              :limit => 64
    t.boolean  "has_index",                                                          :default => false,            :null => false
    t.boolean  "has_bibliography",                                                   :default => false,            :null => false
    t.boolean  "has_glossary",                                                       :default => false,            :null => false
    t.boolean  "has_sidebar",                                                        :default => false,            :null => false
    t.boolean  "has_table_of_contents",                                              :default => false,            :null => false
    t.string   "audience",                                                           :default => "Primary school", :null => false
    t.integer  "collection_id"
    t.integer  "word_count"
    t.integer  "lexile"
    t.string   "guided_level",          :limit => 4
    t.string   "proprietary_id",        :limit => 16
    t.integer  "catalog_page"
    t.boolean  "has_author_biography",                                               :default => false,            :null => false
    t.boolean  "has_map",                                                            :default => false,            :null => false
    t.boolean  "has_timeline",                                                       :default => false,            :null => false
    t.text     "cip"
    t.string   "lccn",                  :limit => 32
    t.string   "lcclass",               :limit => 32
    t.string   "packager",              :limit => 64
    t.string   "title"
    t.text     "toc"
    t.boolean  "is_spotlight",                                                       :default => true,             :null => false
  end

  create_table "products_teaching_guides", :id => false, :force => true do |t|
    t.integer "product_id"
    t.integer "teaching_guide_id"
  end

  add_index "products_teaching_guides", ["product_id"], :name => "index_products_teaching_guides_on_product_id"

  create_table "products_users", :id => false, :force => true do |t|
    t.integer "product_id"
    t.integer "user_id"
  end

  add_index "products_users", ["user_id"], :name => "index_products_users_on_user_id"

  create_table "recipients", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.string   "emails"
    t.string   "ftp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_automatic", :default => false, :null => false
  end

  add_index "recipients", ["name", "type"], :name => "index_recipients_on_name_and_type", :unique => true

  create_table "related_product_assignments", :force => true do |t|
    t.integer "product_id"
    t.integer "related_product_id"
    t.string  "relation",           :limit => 64
  end

  add_index "related_product_assignments", ["product_id", "relation"], :name => "index_rpa_on_product_id_and_relation"
  add_index "related_product_assignments", ["product_id"], :name => "index_rpa_on_product_id"

  create_table "sales_targets", :force => true do |t|
    t.integer "sales_team_id"
    t.integer "year"
    t.decimal "amount",        :precision => 11, :scale => 2
  end

  create_table "sales_teams", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.string  "category"
    t.integer "managed_by"
    t.string  "phone"
    t.string  "fax"
    t.string  "email"
    t.string  "proprietary_id"
  end

  create_table "sales_zones", :force => true do |t|
    t.string "name"
    t.string "description"
    t.string "proprietary_id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string "name"
    t.string "value"
  end

  create_table "specs", :force => true do |t|
    t.integer  "specable_id"
    t.string   "name",                  :limit => 150, :default => "",    :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "contact_name",          :limit => 32,  :default => "",    :null => false
    t.string   "contact_email",         :limit => 96,  :default => "",    :null => false
    t.string   "contact_telephone",     :limit => 96,  :default => "",    :null => false
    t.text     "customization"
    t.string   "subjectheadings",       :limit => 32
    t.string   "callnumbers",           :limit => 32
    t.string   "capitalization",        :limit => 32
    t.string   "nonfiction",            :limit => 32
    t.string   "individualbio",         :limit => 32
    t.string   "collectivebio",         :limit => 32
    t.string   "fiction",               :limit => 32
    t.string   "story",                 :limit => 32
    t.string   "easy",                  :limit => 32
    t.string   "reference",             :limit => 32
    t.boolean  "include_kits",                         :default => false, :null => false
    t.string   "cards",                 :limit => 32
    t.string   "pockets",               :limit => 32
    t.string   "labels",                :limit => 32
    t.string   "arlabels",              :limit => 32
    t.string   "rclabels",              :limit => 32
    t.boolean  "include_disk",                         :default => false, :null => false
    t.string   "mediaformat",           :limit => 32
    t.string   "mediatype",             :limit => 32
    t.string   "recordformat",          :limit => 32
    t.string   "disksoftware",          :limit => 32
    t.boolean  "include_labels",                       :default => false, :null => false
    t.string   "symbology",             :limit => 32
    t.string   "location",              :limit => 32
    t.string   "position",              :limit => 32
    t.string   "orientation",           :limit => 32
    t.string   "libraryname",           :limit => 32
    t.string   "startnumber",           :limit => 32
    t.string   "endnumber",             :limit => 32
    t.boolean  "include_tests",                        :default => false, :null => false
    t.boolean  "include_readinglabels",                :default => false, :null => false
    t.string   "specable_type"
  end

  create_table "status_changes", :force => true do |t|
    t.integer  "status_changeable_id"
    t.string   "status"
    t.datetime "created_at"
    t.string   "status_changeable_type"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "teaching_guides", :force => true do |t|
    t.string   "name"
    t.text     "rationale"
    t.text     "objective"
    t.integer  "interest_level_min_id"
    t.integer  "interest_level_max_id"
    t.text     "body"
    t.string   "document"
    t.integer  "download_counter",      :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "testimonials", :force => true do |t|
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "name",           :limit => 128
    t.string   "company",        :limit => 128
    t.string   "location",       :limit => 128
    t.text     "comment"
    t.string   "proprietary_id", :limit => 16
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "type"
    t.integer  "sales_team_id"
    t.string   "category"
    t.string   "fax",                       :limit => 40
    t.string   "proprietary_id"
  end

  create_table "versions", :force => true do |t|
    t.integer  "versioned_id"
    t.string   "versioned_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "user_name"
    t.text     "modifications"
    t.integer  "number"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reverted_from"
  end

  add_index "versions", ["created_at"], :name => "index_versions_on_created_at"
  add_index "versions", ["number"], :name => "index_versions_on_number"
  add_index "versions", ["tag"], :name => "index_versions_on_tag"
  add_index "versions", ["user_id", "user_type"], :name => "index_versions_on_user_id_and_user_type"
  add_index "versions", ["user_name"], :name => "index_versions_on_user_name"
  add_index "versions", ["versioned_id", "versioned_type"], :name => "index_versions_on_versioned_id_and_versioned_type"

  create_table "wait_a_minute_request_logs", :id => false, :force => true do |t|
    t.string   "ip"
    t.boolean  "refused",    :default => false
    t.datetime "created_at"
  end

  add_index "wait_a_minute_request_logs", ["created_at"], :name => "index_wait_a_minute_request_logs_on_created_at"
  add_index "wait_a_minute_request_logs", ["ip", "created_at", "refused"], :name => "index_all"
  add_index "wait_a_minute_request_logs", ["ip", "created_at"], :name => "ip_by_date_index"
  add_index "wait_a_minute_request_logs", ["ip", "refused"], :name => "refused_ip_index"
  add_index "wait_a_minute_request_logs", ["ip"], :name => "index_wait_a_minute_request_logs_on_ip"

  create_table "zones", :force => true do |t|
    t.string  "name"
    t.string  "code"
    t.integer "country_id"
  end

end
