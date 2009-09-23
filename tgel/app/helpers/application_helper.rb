# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require "tgel"
  include TgelMethods
  require "fusion_charts_helper"
  include FusionChartsHelper
end
