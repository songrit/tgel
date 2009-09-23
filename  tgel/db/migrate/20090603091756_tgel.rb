class Tgel < ActiveRecord::Migration
  def self.up
    create_table "tgel_services", :force => true do |t|
      t.string   "module"
      t.string   "code"
      t.text   "name"
      t.text     "xml"
      t.string   "auth"
      t.boolean  "listed"
      t.integer  "tgel_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tgel_xmains", :force => true do |t|
      t.string   "status"
      t.text     "xvars",           :limit => 2147483647
      t.datetime "start"
      t.integer  "tgel_service_id"
      t.datetime "stop"
      t.integer  "current_runseq"
      t.string   "name"
      t.integer  "location_id"
      t.integer  "tgel_user_id"
      t.text "ip"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "tgel_xmains", ["tgel_service_id"], :name => "tgel_service"

    create_table "tgel_runseqs", :force => true do |t|
      t.string   "action"
      t.string   "status",      :limit => 1
      t.string   "code"
      t.text     "name"
      t.integer  "location_id"
      t.string   "role"
      t.string   "rule"
      t.integer  "tgel_xmain_id"
      t.integer  "step"
      t.integer  "form_step"
      t.datetime "start"
      t.datetime "stop"
      t.boolean  "end"
      t.text     "xml"
      t.integer  "tgel_user_id"
      t.text "ip"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "tgel_runseqs", ["code"], :name => "code"
    add_index "tgel_runseqs", ["tgel_xmain_id"], :name => "xmain"

    create_table "tgel_docs", :force => true do |t|
      t.string   "name"
      t.string   "filename"
      t.string   "content_type"
      t.binary   "data",         :limit => 2147483647
      t.integer  "tgel_xmain_id"
      t.integer  "tgel_runseq_id"
      t.integer  "tgel_user_id"
      t.text "ip"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tgel_ws_queues", :force => true do |t|
      t.string   "url"
      t.string   "poll_url"
      t.string   "status",       :limit => 1
      t.integer  "tgel_runseq_id"
      t.datetime "next_poll_at"
      t.integer  "wait"
      t.integer  "tgel_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tgel_redirect_queues", :force => true do |t|
      t.string   "url"
      t.string   "status"
      t.integer  "tgel_runseq_id"
      t.integer  "tgel_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tgel_roles", :force => true do |t|
      t.string   "code"
      t.string   "name"
      t.integer  "tgel_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tgel_songrits", :force => true do |t|
      t.string   "code"
      t.string   "value"
      t.text     "description"
      t.integer  "tgel_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tgel_users", :force => true do |t|
      t.string   "login"
      t.string   "password"
      t.string   "email"
      t.string   "title"
      t.string   "fname"
      t.string   "lname"
      t.string   "role"
      t.string   "cellphone"
      t.string   "photo"
      t.string   "org"
      t.string   "position"
      t.integer  "tgel_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    create_table :tgel_logs do |t|
      t.string :log_type
      t.text :message
      t.string :controller
      t.string :action
      t.text :params
      t.text :session
      t.integer :tgel_user_id

      t.timestamps
    end

  end

  def self.down
    drop_table "tgel_services"
    drop_table "tgel_xmains"
    drop_table "tgel_runseqs"
    drop_table "tgel_docs"
    drop_table "tgel_ws_queues"
    drop_table "tgel_redirect_queues"
    drop_table "tgel_roles"
    drop_table "tgel_songrits"
    drop_table "tgel_users"
    drop_table "tgel_logs"
  end
end
