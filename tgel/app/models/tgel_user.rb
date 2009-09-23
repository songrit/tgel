class TgelUser < ActiveRecord::Base
  has_many :tgel_xmains
  has_many :tgel_logs
  has_many :tgel_docs
  validates_uniqueness_of :login

end
