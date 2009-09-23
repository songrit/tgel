class TgelLog < ActiveRecord::Base
  serialize :params
  serialize :session

  belongs_to :tgel_users
end
