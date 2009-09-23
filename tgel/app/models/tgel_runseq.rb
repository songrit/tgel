class TgelRunseq < ActiveRecord::Base
  belongs_to :tgel_xmain
  named_scope "form_action", :conditions=>['action=? OR action=?','form','output']
end
