def win32?
  !(RUBY_PLATFORM =~ /win32/).nil?
end

namespace :tgel do
  desc "init tgel app"
  task :init=>:environment do
    unless File.exists?("index.mm")
      if win32?
        system "type null > main.mm"
        system "rename public\\index.html public\\index0.html"
        system "mkdir db\\migrate"
        system "xcopy vendor\\plugins\\tgel\\db\\migrate\\*.rb db\\migrate"
        system "xcopy vendor\\plugins\\tgel\\public\\images\\*.* public\\images"
        system "xcopy vendor\\plugins\\tgel\\public\\stylesheets\\*.* public\\stylesheets"
        system "xcopy vendor\\plugins\\tgel\\public\\javascripts\\*.* public\\javascripts"
        system "xcopy vendor\\plugins\\tgel\\app\\models\\*.rb app\\models"
        system "xcopy vendor\\plugins\\tgel\\public\\index.mm ."
        system "xcopy vendor\\plugins\\tgel\\public\\routes.rb config"
        system "xcopy vendor\\plugins\\tgel\\helper\\application_helper.rb app\\helpers"
        system "xcopy vendor\\plugins\\tgel\\app\\controllers\\application_controller.rb app\\controllers"
        system "xcopy vendor\\plugins\\tgel\\app\\views\\layouts\\application.haml app\\views\\layouts"
        system "xcopy vendor\\plugins\\tgel\\public\\index.haml app\\views\\welcome"
        system "xcopy vendor\\plugins\\tgel\\start.bat ."
      else
        system "echo -n > main.mm"
        system "mv public/index.html public/index0.html"
        system "rsync -ruv vendor/plugins/tgel/db/migrate db"
        system "rsync -ruv vendor/plugins/tgel/public ."
        system "rsync -ruv vendor/plugins/tgel/app/models app"
        system "cp -ruv vendor/plugins/tgel/public/index.mm ."
        system "cp -ruv vendor/plugins/tgel/public/routes.rb config"
        system "cp vendor/plugins/tgel/helper/application_helper.rb app/helpers"
        system "cp vendor/plugins/tgel/app/controllers/application_controller.rb app/controllers"
        system "cp vendor/plugins/tgel/app/views/layouts/application.haml app/views/layouts"
        system "cp vendor/plugins/tgel/public/index.haml app/views/welcome"
        system "cp vendor/plugins/tgel/start.bat ."
      end
      system "rake db:migrate"
      TgelUser.create :id=>1, :login=>"anonymous", :title=>"", :fname=>"anonymous", :lname=>""
      system "ruby script/plugin install http://ennerchi.googlecode.com/svn/trunk/plugins/jrails --force"
    else
      puts "File index.mm exists, abort TGEL initialization process."
    end
  end

  desc "sync db/migrate and public"
  task :sync do
    if win32?
      system "xcopy vendor\\plugins\\tgel\\db\\migrate\\*.rb db\\migrate"
      system "xcopy vendor\\plugins\\tgel\\public public /y/e"
    else
      system "rsync -ruv vendor/plugins/tgel/db/migrate db"
      system "rsync -ruv vendor/plugins/tgel/public ."
    end
  end
end

