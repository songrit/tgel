def win32?
  !(RUBY_PLATFORM =~ /win32/).nil?
end

namespace :tgel do
  desc "init tgel app"
  task :init do
    unless File.exists?("index.mm")
      if win32?
        #`type null > main.mm`
        system "mkdir db\\migrate"
        system "xcopy vendor\\plugins\\tgel\\db\\migrate db\\migrate /y/e"
        system "xcopy vendor\\plugins\\tgel\\public public /y/e"
        system "xcopy vendor\\plugins\\tgel\\public\\index.mm . /y/e"
        system "xcopy vendor\\plugins\\tgel\\public\\routes.rb config /y/e"
        system "xcopy vendor\\plugins\\tgel\\app\\helpers\\application_helper.rb app\\helpers /y/e"
        system "xcopy vendor\\plugins\\tgel\\app\\controllers\\application_controller.rb app\\controllers /y/e"
      else
        #system "echo -n > main.mm"
        system "rsync -ruv vendor/plugins/tgel/db/migrate db"
        system "rsync -ruv vendor/plugins/tgel/public ."
        system "cp -ruv vendor/plugins/tgel/public/index.mm ."
        system "cp -ruv vendor/plugins/tgel/public/routes.rb config"
        system "cp vendor/plugins/tgel/app/helpers/application_helper.rb app/helpers"
        system "cp vendor/plugins/tgel/app/controllers/application_controller.rb app/controllers"
      end
      system "rake db:migrate"
      system "ruby script/plugin install http://ennerchi.googlecode.com/svn/trunk/plugins/jrails"
    else
      puts "File index.mm exists, abort TGEL initialization process."
    end
  end

  desc "sync db/migrate and public"
  task :sync do
    if win32?
      system "xcopy vendor\\plugins\\tgel\\db\\migrate db\\migrate /y/e"
      system "xcopy vendor\\plugins\\tgel\\public public /y/e"
    else
      system "rsync -ruv vendor/plugins/tgel/db/migrate db"
      system "rsync -ruv vendor/plugins/tgel/public ."
    end
  end
end

