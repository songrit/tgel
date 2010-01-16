class TgelUser < ActiveRecord::Base
  has_many :tgel_xmains
  has_many :tgel_logs
  has_many :tgel_docs
  validates_uniqueness_of :login

  def self.authenticate(login,password)
    find_by_login_and_password login, TgelUser.sha1(password)
  end
  def password=(pwd)
    write_attribute "password", TgelUser.sha1(pwd)
  end

  protected
  def self.sha1(s)
    Digest::SHA1.hexdigest(s)
  end
end
