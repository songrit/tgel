class EngineController < ApplicationController
#  require "tgel"
#  include TgelMethods
  require "erb"
  include ERB::Util

  def init
    @service= TgelService.first :conditions=>['module=? AND code=?',
      params[:module], params[:service] ]
    if authorize_init?
      xmain = create_xmain(@service)
      result = create_runseq(xmain)
      unless result
        message = "cannot find action for xmain #{xmain.id}"
        tgel_log("ERROR", message)
        flash[:notice]= message
        redirect_to_root and return
      end
      xmain.update_attribute(:xvars, @xvars)
      xmain.tgel_runseqs.last.update_attribute(:end,true)
      redirect_to :action=>'run', :id=>xmain.id
    else
      flash[:notice]= "ขออภัย ไม่สามารถทำงานได้เนื่องจากปัญหาอำนาจดำเนินการ"
      redirect_to_root
    end
  end
  def run
    init_vars(params[:id])
    #    @xmain= TgelXmain.find params[:id]
    #@runseq= TgelRunseq.find @xmain.current_runseq
    @runseq = TgelRunseq.find params[:runseq] if params[:runseq]
    if non_fork?(@runseq.action)
      redirect_to(:action=>"run_#{@runseq.action}", :id=>@xmain) and return
    else
      @runseq= @xmain.tgel_runseqs.find(:first, :order=>'step', :conditions=>"status!='F' AND id>=#{@xmain.current_runseq}") unless params[:runseq]
      if authorize?(@runseq)
          tgel_debug "run_#{@runseq.action}: xmain #{@xmain.id} #{@xmain.name}, runseq #{@runseq.id} #{@runseq.code}: #{@runseq.name}"
          redirect_to :action=>"run_#{@runseq.action}", :id=>@xmain and return
#        end
      else
        redirect_to_root
      end
    end
  end
  def tgel_debug(s)
    File.open("log/tgel.log", "a") do |f|
      f.puts "#{Time.now}-#{current_user.login}:#{s}"
    end
  end
  def cancel
    TgelXmain.find(params[:id]).update_attributes :status=>'X'
    redirect_to_root
  end

  def run_invoke # kaddressbook
    init_vars(params[:id])
    m, s = discover_service(@runseq.code)
    # logger.debug "discover #{m}, #{s}"
    service= TgelService.first :conditions=>['module=? AND code=?', m,s ]
    @invoke_xvars= @xvars
    xmain = create_xmain(service)
    create_runseq(xmain)
    @xvars[:invoke_xvars]= @invoke_xvars
    xmain.update_attribute(:xvars, @xvars)
    xmain.tgel_runseqs.last.update_attribute(:end,true)
    @xvars= @invoke_xvars #restore current @xvars
    end_action
  rescue => e
    @xmain.status='E'
    @xvars[:error]= e
    flash[:notice]= "ERROR: Job Abort<br/>#{xml_text e}<hr/>"
    end_action(nil)
  end
  def run_form
    init_vars(params[:id])
    @title= "รหัสดำเนินการ #{@xmain.id}: #{@xmain.name}"
    service= @xmain.tgel_service
    if service
      f= "app/views/#{service.module}/#{service.code}/#{@runseq.code}.rhtml"
      @ui= File.read(f)
      @message = "ดำเนินการต่อ"
      @message = "สิ้นสุดการทำงาน" if @runseq.end
    else
      flash[:notice]= "ไม่สามารถค้นหาบริการที่ต้องการได้"
      redirect_to_root
    end
#    @sign = affirm(get_option("sign"))
#    if @sign
#      eval "@xvars[:#{@runseq.code}_original_doc] = render_to_string(:inline=>@ui, :layout=>'utf8')"
#      @xmain.xvars= @xvars
#      @xmain.save
#    end
  end
  def sign_form
    init_vars(params[:xmain_id])
    eval "@xvars[:#{@runseq.code}] = params"
    params.each { |k,v| get_image(k, params[k]) }
    @xmain.xvars= @xvars
    @xmain.save
    @user= current_user || TgelUser.new
    @system_attributes= %w(commit step authenticity_token action runseq_id controller login xmain_id)
    data_text= render_to_string(:template=>"engine/sign_form_print", :layout=>"utf8")
    @tgel_doc= TgelDoc.create :name=> @runseq.name,
      :content_type=>"temp", :data_text=> data_text,
      :tgel_xmain_id=>@xmain.id, :tgel_runseq_id=>@runseq.id, :tgel_user_id=>session[:user_id],
      :ip=> get_ip, :tgel_service_id=>@xmain.tgel_service_id
    digest= EzCrypto::Digester.digest64(data_text)
    digest.gsub!(' ','%20')
    digest.gsub!('+','%2B')
    digest.gsub!('=','%3D')
    digest.gsub!("\n",'')
    callback= "#{url_for :action=>:print_sign_form, :id=>@tgel_doc.id}"
#    doc= "http://#{request.env['HTTP_HOST']}#{url_for :action=>:validate, :id=>@tgel_doc.id}"
    #headers["Status"] = "301 Moved Permanently"
    #redirect_to "http://#{songrit('localhost')}/engine/signing?digest=#{digest}&login=#{current_user.login}&callback=#{callback}"
#    headers["Status"] = "301 Moved Permanently"
    @redirect = "http://#{songrit('localhost')}/engine/signing?login=#{current_user.login}&callback=#{callback}&digest=#{digest}"
  end
  def print_sign_form
    @tgel_doc= TgelDoc.find params[:id]
    signature= params[:sig].gsub('%2B','+')
    signature.gsub!(' ','+')
    @tgel_doc.signature= signature
    @tgel_doc.content_type= "signed document"
    @tgel_doc.save
    init_vars(@tgel_doc.tgel_xmain_id)
    @message = @runseq.end ? "สิ้นสุดการทำงาน" : "ดำเนินการต่อ"
  end
  def end_sign_form
    init_vars(params[:xmain_id])
    end_action
  end
#  def end_form
#    init_vars(params[:xmain_id])
#    eval "@xvars[:#{@runseq.code}] = params"
#    params.each { |k,v| get_image(k, params[k]) }
#    end_action
#  end
  def end_form
    init_vars(params[:xmain_id])
    eval "@xvars[:#{@runseq.code}] = {} unless @xvars[:#{@runseq.code}]"
    params.each { |k,v|
      if params[k].respond_to? :original_filename
        get_image(k, params[k])
      else
        eval "@xvars[:#{@runseq.code}][:#{k}] = v"
      end
    }
    end_action
  end
  def run_output
    init_vars(params[:id])
    service= @xmain.tgel_service
    if service
      f= "app/views/#{service.module}/#{service.code}/#{@runseq.code}.rhtml"
      @ui= File.read(f)
      @tgel_doc= TgelDoc.create :name=> @runseq.name,
        :content_type=>"output", :data_text=> render_to_string(:inline=>@ui, :layout=>"utf8"),
        :tgel_xmain_id=>@xmain.id, :tgel_runseq_id=>@runseq.id, :tgel_user_id=>session[:user_id],
        :ip=> get_ip, :tgel_service_id=>service.id
      @message = "ดำเนินการต่อ"
      @message = "สิ้นสุดการทำงาน" if @runseq.end
      eval "@xvars[:#{@runseq.code}] = url_for(:controller=>'engine', :action=>'document', :id=>@tgel_doc)"
    else
      flash[:notice]= "ไม่สามารถค้นหาบริการที่ต้องการได้"
      redirect_to_root
    end
    display= get_option("display")
    if display && !affirm(display)
      end_action
    end
  end
  def end_output
    init_vars(params[:xmain_id])
    end_action
  end
  def run_ws
    init_vars(params[:id])
    href= render_to_string :inline=>get_option('url', @runseq)
    result= http(href)
    eval "@xvars[:#{@runseq.code}] = result"
    end_action
  end
  # old ws post to queue and gets run by Nso::LaborController#pending_tasks
  # which call EngineController#ws_dispatch
  def run_ws0
    init_vars(params[:id])
    href= render_to_string :inline=>get_option('url', @runseq)
    if request.remote_ip=="127.0.0.1"
      @xvars[@runseq.code.to_sym]= @xvars[:result] = 'ws not call because running from localhost'
    else
      TgelWsQueue.create :tgel_runseq_id=>@runseq.id, :url=>href, :poll_url=>href,
        :next_poll_at=> Time.now, :wait=>WS_WAIT, :status=>'I', :user_id=>get_user.id
    end
    end_action
  end
  def run_call
    init_vars(params[:id])
    # change from 'fork' (use in nso project) to 'background'
    if affirm(get_option('background', @runseq))
      fork "engine/run_call_background/#{@runseq.id}"
    else
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      $runseq_id= @runseq.id; $user_id= get_user.id
      result= eval("#{@xvars[:custom_controller]}.new.#{@runseq.code}")
      init_vars_by_runseq($runseq_id)
      @xvars[@runseq.code.to_sym]= result
      @xvars[:current_step]= @runseq.step
      @runseq.status= 'F' #finish
      @runseq.stop= Time.now
      @runseq.save
    end
    end_action
  rescue => e
    @xmain.status='E'
    @xvars[:error]= e
    @xmain.xvars= @xvars
    @xmain.save
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    flash[:notice]= "ERROR: Job Abort xmain #{@xmain.id} runseq #{@runseq.id}<br/>#{xml_text e}<hr/>"
    tgel_log("ERROR", "run_call: #{xml_text e}")
#    end_action(nil)
#    end_action
    redirect_to_root
  end
  def run_call_background # pass params runseq_id
    init_vars_by_runseq(params[:id])
    m = name2camel(@xmain.tgel_service.app.code)
    c = name2camel(@xmain.tgel_service.module)
    controller= "#{m}::#{c}Controller"
    # mark F to avoid infinite loop in case controller error
    @runseq.status= 'F'
    $runseq_id= @runseq.id
    result= eval("#{controller}.new.#{@runseq.code}")
    init_vars_by_runseq($runseq_id)
    @xvars[@runseq.code.to_sym]= result
    @xvars[:current_step]= @runseq.step
    #end_action
    @xmain.xvars= @xvars
    @xmain.save
    @runseq.status= 'F' #finish
    @runseq.stop= Time.now
    @runseq.save
    render :text => "Done: #{@runseq.id} #{@runseq.code} at #{Time.now}"
  end
  def run_if
    init_vars(params[:id])
    condition= eval(@runseq.code)
    match_found= false
    if condition
      xml= REXML::Document.new(@runseq.xml).root
      next_runseq= nil
      xml.each_element('node') do |node|
        text= node.attributes['TEXT']
        match, name= text.split(':',2)
        label= name2code(name.strip)
        if condition==match
          next_runseq= @xmain.tgel_runseqs.first :conditions=>['code=?',label]
          match_found= true
          @runseq_not_f= false
          # mark runseq and all subsequence to be 'R' if 'F'
          @xmain.tgel_runseqs.all(:conditions=>["step >= ?", next_runseq.step]).each do |runseq|
            runseq.status= 'R' if runseq.status=='F'
            @runseq_not_f= true if runseq.id==@runseq.id
            runseq.save
          end
        end
      end
    end
    unless match_found
      next_runseq= @xmain.tgel_runseqs.find :first, :conditions=>"step=#{@xvars[:current_step]+1}"
    end
    end_action(next_runseq)
  end
  def ws_dispatch
    TgelWsQueue.all(:conditions=>["status != 'F'"]).each do |ws|
      puts "Time now is #{Time.now} next poll at is #{ws.next_poll_at}\n"
      next if Time.now < ws.next_poll_at
      puts "process #{ws.id}"
      result= REXML::Document.new(http(ws.poll_url)).root
      if result and result.elements['async']
        ws.poll_url= result.elements['async'].attributes['poll_url']
        wait= result.elements['async'].attributes['wait'].to_i
        ws.wait = wait unless wait==0
        ws.next_poll_at = Time.now + ws.wait*60
        ws.status= 'R'
        ws.save
      else
        @runseq= TgelRunseq.find ws.tgel_runseq_id
        @xmain= @runseq.tgel_xmain
        @xvars= @xmain.xvars
        @xvars[@runseq.code.to_sym] = @xvars[:result]= result.to_s
        ws.status= 'F'
        @runseq.status='F'
        @xmain.xvars= @xvars
        @xmain.save; @runseq.save; ws.save
      end
    end
    render :text => "done"
  end
  def run_redirect
    init_vars(params[:id])
    next_runseq= @xmain.tgel_runseqs.first :conditions=>["action!='redirect' AND code= ?",@runseq.code]
#    next_runseq= @xmain.tgel_runseqs.find :first, :conditions=>"step=#{@xvars[:current_step]+1}" unless next_runseq
    if next_runseq.step < @runseq.step
      # mark runseq and all subsequence to be 'R' if 'F'
      @xmain.tgel_runseqs.all(:conditions=>["step >= ?", next_runseq.step]).each do |runseq|
        next unless runseq.status=='F'
        runseq.status= 'R'
        runseq.save
      end
    else
      # mark all skip runseqs to be 'F'
      @xmain.tgel_runseqs.all(:conditions=>["step < ?", next_runseq.step]).each do |runseq|
        next if runseq.status=='F'
        runseq.status= 'F'
        runseq.save
      end
    end
    @xmain.current_runseq= next_runseq.id
    end_action(next_runseq)
  end
  def document
    #doc = Doc.find(params[:id])
    #doc = TgelDoc.first :conditions=>"id = #{params[:id]}"
    doc = TgelDoc.find params[:id]
    if doc
      if %w(output temp).include?(doc.content_type)
        render :text=>doc.data_text
      else
        data= read_binary("doc/f#{params[:id]}")
        send_data(data, :filename=>doc.filename, :type=>doc.content_type, :disposition=>"attachment")
      end
    else
      data= read_binary("public/images/img_not_found.png")
      send_data(data, :filename=>"img_not_found.png", :type=>"image/png", :disposition=>"attachment")
    end
  end
  def signed_document
    @doc = TgelDoc.find params[:id]
    render :layout=>false
#  rescue
#    render :text=>"ขออภัย ไม่สามารถค้นหาเอกสารได้"
  end
  def read_binary(path)
    File.open path, "rb" do |f| f.read end
  end

  private
  def create_xmain(service)
    c = name2camel(service.module)
    custom_controller= "#{c}Controller"
    TgelXmain.create :tgel_service_id=>service.id,
      :start=>Time.now,
      :name=>service.name,
      :ip=> get_ip,
      :status=>'I', # init
      :tgel_user_id=>get_user.id,
      :xvars=> {
        :tgel_service_id=>service.id, :p=>params,
        :id=>params[:id],
        :user_id=>get_user.id, :custom_controller=>custom_controller,
        :referer=>request.env['HTTP_REFERER'] }
  end
  def create_runseq(xmain)
    @xvars= xmain.xvars
    default_role= get_default_role
    xml= xmain.tgel_service.xml
    root = REXML::Document.new(xml).root
    i= 0; j= 0 # i= step, j= form_step
    root.elements.each('node') do |activity|
      text= activity.attributes['TEXT']
      next if tgel_comment?(text)
      action= freemind2action(activity.elements['icon'].attributes['BUILTIN']) if activity.elements['icon']
      return false unless action
      i= i + 1
      output_display= false
      if action=='output'
        display= get_option_xml("display", activity)
        if display && !affirm(display)
          output_display= false
        else
          output_display= true
        end
      end
      j= j + 1 if (action=='form' || output_display)
      @xvars[:referer] = activity.attributes['TEXT'] if action=='redirect'
      if action!= 'if'
        scode, name= text.split(':', 2)
        name ||= scode; name.strip!
        code= name2code(scode)
      else
        code= text
        name= text
      end
      role= get_option_xml("role", activity) || default_role
      rule= get_option_xml("rule", activity) || "true"
      runseq= TgelRunseq.create :tgel_xmain_id=>xmain.id,
        :name=> name, :action=> action,
        :code=> code, :role=>role.upcase, :rule=> rule,
        :step=> i, :form_step=> j, :status=>'I',
        :xml=>activity.to_s
      xmain.current_runseq= runseq.id if i==1
    end
    @xvars[:total_steps]= i
    @xvars[:total_form_steps]= j
  end
  def init_vars(xmain)
    @xmain= TgelXmain.find xmain
    @xvars= @xmain.xvars
    @runseq= @xmain.tgel_runseqs.find @xmain.current_runseq
    authorize?
    @xvars[:current_step]= @runseq.step
    unless params[:action]=='run_call'
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      @runseq.save
    end
  end
  def init_vars_by_runseq(runseq_id)
    @runseq= TgelRunseq.find runseq_id
    @xmain= @runseq.tgel_xmain
    @xvars= @xmain.xvars
    #@xvars[:current_step]= @runseq.step
    @runseq.start ||= Time.now
    @runseq.status= 'R' # running
    @runseq.save
  end
  def get_image(key, params)
    doc = TgelDoc.create(
      :name=> key.to_s, :tgel_user_id=>current_user.id,
      :tgel_xmain_id=> @xmain.id,
      :tgel_runseq_id=> @runseq.id,
      :filename=> params.original_filename,
      :content_type => params.content_type || 'application/zip'
      #        :data=> params.read)
    )
    File.open("doc/f#{doc.id}","wb") { |f|
      f.puts(params.read)
    }
    eval "@xvars[:#{@runseq.code}][:#{key}] = '#{url_for(:action=>'document', :id=>doc.id)}' "
    eval "@xvars[:#{@runseq.code}][:#{key}_doc_id] = #{doc.id} "
  end
  def end_action(next_runseq = nil)
    @runseq.status='F' unless @runseq_not_f
    @runseq.tgel_user_id= session[:user_id]
    @runseq.stop= Time.now
    @runseq.save
    @xmain.xvars= @xvars
    @xmain.status= 'R' # running
    @xmain.save
    next_runseq= @xmain.tgel_runseqs.find(:first, :order=>'step', :conditions=>"status != 'F'") unless next_runseq
    unless next_runseq # job finish
      @xmain.xvars= @xvars
      @xmain.status= 'F' unless @xmain.status== 'E' # finish
      @xmain.stop= Time.now
      @xmain.save
      redirect_to_root and return
    end
    if fork_action?(next_runseq.action)
      has_role= authorize?(next_runseq)
    end
    if has_role
      @xmain.current_runseq= @runseq.id
      @xmain.save
      redirect_to :action=>'run', :id=>@xmain.id, :runseq=>@runseq.id and return
    else
      redirect_to_root and return
    end
  end
  def discover_service(code)
    m,s = code.split("/")
    # use existing module as default if mm not specify module
    ( s= m ; m= @xmain.tgel_service.module ) unless s
    return m,s
  end
end
