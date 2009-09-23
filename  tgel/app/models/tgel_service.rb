class TgelService < ActiveRecord::Base
  require "tgel"
  include TgelMethods

  has_many :tgel_xmains
  has_many :tgel_docs

  def authorized_task?(user)
    return false unless user
    default_role= get_default_role
    xml= self.xml
    root = REXML::Document.new(xml).root
    first_activity= root.elements['node']
    role= get_option_xml("role", first_activity) || default_role
    if role.blank?
      return true
    else
      return user.role ? user.role.upcase.split(',').include?(role.upcase) : false
    end
  end
end
