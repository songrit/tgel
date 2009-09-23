class TgelController < ActionController::Base
#  require "tgel"
#  include TgelMethods
  layout "application"

  def view_mm
    Dir["*.mm"].each do |f|
      FileUtils.copy(f, "public/#{f}")
    end
  end
  def update_app
    @t = [cancel_pending_xmains]
    @t << process_roles
    @t << "if you change models in freemind, please destroy scaffold and tables before update app"
    @t << process_models
    @t << exec_cmd("rake db:migrate").gsub("\n","<br/>")
    @t << process_services
    @t << gen_controllers
    @t << gen_views
    @t << "Application Updated, please restart Rails server"
    ActionController::Routing::Routes.reload
  end
  private
  def gen_views
    doc= get_app
    modules= doc.elements["//node/node[@TEXT='services']"] || REXML::Document.new
    t = ["generate ui<br/>"]
    modules.each_element('node') do |modul|
      module_name= modul.attributes['TEXT']
      next if module_name.comment?
      mname= name2code(module_name)
      modul.each_element('node') do |service|
        # must do this beforre calling name2code which will strip all symbols
        service_name= service.attributes['TEXT']
        next if service_name.comment?
        sname= name2code(service_name)
        dir ="app/views/#{mname}/#{sname}"
        unless File.exists?(dir)
          Dir.mkdir(dir)
          t << "create directory #{dir}"
        end
        service.each_element('node') do |activity|
          icon = activity.elements['icon']
          next unless icon
          action= freemind2action(icon.attributes['BUILTIN'])
          next unless ui_action?(action)
          code_name = activity.attributes["TEXT"].to_s
          next if code_name.comment?
          code= name2code(code_name)
          f= "app/views/#{mname}/#{sname}/#{code}.rhtml"
          unless File.exists?(f)
            ff=File.open(f, 'w'); ff.close
            t << "create file #{f}"
          end
        end
      end
    end
    t.join("<br/>")
  end
  def gen_controllers
    t = ["generate controllers<br/>"]
    modules= TgelService.all :group=>'module'
    modules.each do |m|
      next if controller_exists?(m.module)
      t << "= #{m.module}"
      t << exec_cmd("ruby script/generate controller #{m.module}")
      #add_tgel_to_controller(m.module)
    end
    t.join("<br/>")
  end

  def process_services
    t= ["process services"]
    xml= get_app
#    TgelService.delete_all
    protected_tgel_service_array = Array.new
    @services= xml.elements["//node[@TEXT='services']"] || REXML::Document.new
    @services.each_element('node') do |m|
      ss= m.attributes["TEXT"]
      code, name= ss.split(':', 2)
      next unless code
      next if code.comment?
      module_code= name2code(code)
      m.each_element('node') do |s|
        service_name= s.attributes["TEXT"].to_s
        t << "= #{module_code}::#{service_name}"
        scode, sname= service_name.split(':', 2)
        sname ||= scode; sname.strip!
        count = TgelService.count(:all, :conditions=>["module=? AND code=?",module_code,name2code(scode)])
        if count==0
          tgel_service = TgelService.create(
            :module=>module_code,
            :code=>name2code(scode),
            :xml=>s.to_s,
            :name=>sname,
            :listed=>listed(s)
          )
          protected_tgel_service_array = protected_tgel_service_array << tgel_service
        else
          tgel_service = TgelService.find(:first, :conditions=>["module=? AND code=?",module_code,name2code(scode)])
          tgel_service.update_attributes(
            :xml=>s.to_s,
            :name=>sname,
            :listed=>listed(s)
          )
          protected_tgel_service_array = protected_tgel_service_array << tgel_service
        end
      end
    end
    TgelService.delete_all(["id NOT IN (?)",protected_tgel_service_array])
    t.join("<br/>")
  end
  def cancel_pending_xmains
    TgelXmain.update_all("status='X'", "status='I' or status='R'")
    "all pending tasks are cancelled."
  end
  def process_models
    @app= get_app
    t= ["process models"]
    models= @app.elements["//node[@TEXT='models']"] || REXML::Document.new
    models.each_element('node') do |model|
      t << "= "+model.attributes["TEXT"]
      model_name= model.attributes["TEXT"]
      next if model_name.comment?
      model_code= name2code(model_name)
      unless model_exists?(model_code)
        attr_list= make_fields(model)+" tgel_user_id:integer"
        t << "ruby script/generate scaffold #{model_code} #{attr_list} --force<br/>"
        t << exec_cmd("ruby script/generate scaffold #{model_code} #{attr_list} --force").gsub("\n","<br/>")
        # remove custom layout therefore all controller will default to application.rhtml layout
        if win32?
          t << "del app\\views\\layouts\\#{model_code.pluralize}.html.erb"
          exec_cmd "del app\\views\\layouts\\#{model_code.pluralize}.html.erb"
        else
          t << "rm app/views/layouts/#{model_code.pluralize}.html.erb"
          exec_cmd "rm app/views/layouts/#{model_code.pluralize}.html.erb"
        end
      end
    end
    t.join("<br/>")
  end
#  def process_models
#    @app= get_app
#    t= ["process models"]
#    models= @app.elements["//node[@TEXT='models']"] || REXML::Document.new
#    models.each_element('node') do |n|
#      t << "= "+n.attributes["TEXT"]
#      model= name2code(n.attributes["TEXT"])
#      unless model_exists?(model)
#        # TODO: try exec_cmd
#        system "ruby script/destroy model #{model}"
#        cmd= ExecCmd.new("ruby script/generate model #{model}")
#        cmd.run
#        table_name= model.downcase.pluralize
#        migrate= cmd.output.match(/db\/migrate\/\d+_create_#{table_name}.rb/).to_s
#        SchemaMigration.delete migrate.match(/\d{14}/).to_s
#        fields= "create_table :#{table_name}, :force=>true, :options=>'engine=myisam default charset=utf8' do |t|\n"
#        #model2hash(n).each_pair { |k,v| fields << "      t.#{v} :#{k}\n" }
#        fields << make_fields(n)
#        fields << "      t.integer :tgel_user_id"
#        s= File.read migrate
#        ss = s.sub("create_table :#{table_name} do |t|", fields)
#        File.open(migrate, 'w') { |f| f << ss }
#      end
#    end
#    t.join("<br/>")
#  end
  def process_roles
    t = ["process_roles"]
    @app= get_app
    TgelRole.delete_all
    roles= @app.elements["//node[@TEXT='roles']"] || REXML::Document.new
    roles.each_element('node') do |role|
      text= role.attributes['TEXT']
      c,n = text.split(': ')
      next if c.comment?
      TgelRole.create :code=>c.upcase, :name=>n, :tgel_user_id=>get_user
      t << "= #{text}"
    end
    t.join("<br/>")
  end
end
