class TgelDoc < ActiveRecord::Base
  belongs_to :tgel_runseq
  belongs_to :tgel_service
  belongs_to :tgel_user
end
