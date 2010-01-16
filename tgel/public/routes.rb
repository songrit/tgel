ActionController::Routing::Routes.draw do |map|
  map.resources :tgel_logs
  map.connect 'run/:module/:service/:id', :controller=>'engine', :action=>'init'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.root :controller=>"welcome"
end
