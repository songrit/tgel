class TgelXmain < ActiveRecord::Base
  belongs_to :tgel_service
  belongs_to :tgel_user
  has_many :tgel_runseqs, :order=>"step"
  serialize :xvars

  # number of xmains on the specified date
  def self.number(d)
    all(:conditions=>['DATE(created_at) =?', d.to_date]).count
  end
end
