require 'tgel'
ActionView::Base.send(:include, TgelMethods)
ActionController::Base.send(:include, TgelMethods)
