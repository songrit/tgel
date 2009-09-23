class EngineController < ApplicationController
  before_filter [:login?, :active?], :except=>['run_call_background', 'ws_dispatch', 'document']
  def index
    # list pending jobs
  end
  def cancel
    Xmain.find(params[:id]).update_attributes :status=>'X'
    redirect_to_root
  end
  def init
    #@app= App.find_by_code params[:app]
    service= TgelService.find :first, :conditions=>['module=? AND code=?',
      params[:module], params[:service]
    ]
    xmain = create_xmain(service)
    create_runseq(xmain)
    xmain.update_attribute(:xvars, @xvars)
    xmain.runseqs.last.update_attribute(:end,true)
    redirect_to :action=>'run', :id=>xmain.id
  end
  def run
    @xmain= Xmain.find params[:id]
    @runseq= Runseq.find @xmain.current_runseq
    if authorize?
      if check_wait
        redirect_to_root
      else
        redirect_to :action=>"run_#{@runseq.action}", :id=>@xmain and return
      end
    else
      redirect_to_root
    end
  end
  def run_form
    init_vars(params[:id])
    service= @xmain.tgel_service
    @app= service.app
    f= "tgel/#{@app.code}/ui/#{service.module}/#{service.code}/#{@runseq.code}.rhtml"
    @ui= File.read(f)
    render :layout=>"tgel/#{@app.code}/ui/layout.rhtml"
  end
  def end_form
    init_vars(params[:xmain_id])
    eval "@xvars[:#{@runseq.code}] = params"
    params.each { |k,v| get_image(k, params[k]) }
    end_action
  end
  def run_ws
    init_vars(params[:id])
    href= render_to_string :inline=>get_option('url', @runseq)
    if request.remote_ip=="127.0.0.1"
      @xvars[@runseq.code.to_sym]= @xvars[:result] = 'ws not call because running from localhost'
    else
      WsQueue.create :runseq_id=>@runseq.id, :url=>href, :poll_url=>href,
        :next_poll_at=> Time.now, :wait=>WS_WAIT, :status=>'I', :user_id=>session[:user].id
    end
    end_action
  end
  def run_call
    init_vars(params[:id])
    if affirm(get_option('fork', @runseq))
      fork "engine/run_call_background/#{@runseq.id}"
    else
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      $runseq_id= @runseq.id; $user_id= session[:user].id
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
    flash[:notice]= "ERROR: Job Abort<hr/>#{e}"
    end_action(nil)
  end
  def run_call_background # pass params runseq_id
    init_vars_by_runseq(params[:id])
    m = name2camel(@xmain.tgel_service.app.code)
    c = name2camel(@xmain.tgel_service.module)
    controller= "#{m}::#{c}Controller"
    $runseq_id= @runseq.id
    result= eval("#{controller}.new.#{@runseq.code}")
    init_vars_by_runseq($runseq_id)
    @xvars[@runseq.code.to_sym]= result
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
    xml= REXML::Document.new(@runseq.xml).root
    match_found= false
    next_runseq= nil
    xml.each_element('node') do |node|
      text= node.attributes['TEXT']
      match, name= text.split(':',2)
      label= name2code(name.strip)
      if condition==match
        next_runseq= @xmain.runseqs.first :conditions=>['code=?',label]
        match_found= true
      end
    end
    unless match_found
      next_runseq= @xmain.runseqs.find :first, :conditions=>"step=#{@xvars[:current_step]+1}"
    end
    end_action(next_runseq)
  end
  def ws_dispatch
    WsQueue.all(:conditions=>["status != 'F'"]).each do |ws|
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
        @runseq= Runseq.find ws.runseq_id
        @xmain= @runseq.xmain
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
    # post redirect_queue
#    RedirectQueue.create :runseq_id=> @runseq.id,
#      :url=>@runseq.name, :status=>'I', :user_id=>session[:user].id
    end_action
  end
  def document
    #doc = Doc.find(params[:id])
    doc = Doc.first :conditions=>"id = #{params[:id]}"
    if doc
      send_data(doc.data, :filename=>doc.filename, :type=>doc.content_type, :disposition=>"attachment")
    else
      data= read_binary("public/images/img_not_found.png")
      send_data(data, :filename=>"img_not_found.png", :type=>"image/png", :disposition=>"attachment")
    end
  end
  def read_binary(path)
    File.open path, "rb" do |f| f.read end
  end
  private
  def end_action(next_runseq = @xmain.runseqs.find(:first, :conditions=>"step=#{@xvars[:current_step]+1}"))
    if next_runseq
      @xmain.current_runseq= next_runseq.id
      @xmain.xvars= @xvars
      @xmain.status= 'R' # running
      @xmain.save
      unless params[:action]=='run_call'
        @runseq.status= 'F' #finish 
        @runseq.stop= Time.now
        @runseq.save
      end
      redirect_to :action=>'run', :id=>@xmain and return
    else # job finish
      @xmain.xvars= @xvars
      @xmain.status= 'F' # finish
      @xmain.stop= Time.now
      @xmain.save
      unless params[:action]=='run_call'
        @runseq.status= 'F' #finish
        @runseq.user_id= session[:user].id
        @runseq.stop= Time.now
        @runseq.save
      end
      #redirect_to_root and return
      redirect_to @xvars[:referer] and return
    end
  end
  def init_vars(xmain)
    @xmain= Xmain.find xmain
    @xvars= @xmain.xvars
    @runseq= Runseq.find @xmain.current_runseq
    @xvars[:current_step]= @runseq.step
    unless params[:action]=='run_call'
      @runseq.start ||= Time.now
      @runseq.status= 'R' # running
      @runseq.save
    end
  end
  def init_vars_by_runseq(runseq_id)
    @runseq= Runseq.find runseq_id
    @xmain= @runseq.xmain
    @xvars= @xmain.xvars
    #@xvars[:current_step]= @runseq.step
    @runseq.start ||= Time.now
    @runseq.status= 'R' # running
    @runseq.save
  end
  def get_image(key, params)
    if params.respond_to? :original_filename
      doc = Doc.create(
        :name=> key.to_s,
        :xmain_id=> @xmain.id,
        :runseq_id=> @runseq.id, 
        :filename=> params.original_filename,
        :content_type => params.content_type || 'application/zip', 
        :data=> params.read)
      eval "@xvars[:#{@runseq.code}][:#{key}] = '#{url_for(:host=>HOST, :action=>'document', :id=>doc.id)}' "
      eval "@xvars[:#{@runseq.code}][:#{key}_doc_id] = #{doc.id} "
    end
  end
  def create_xmain(service)
    #app= service.app
    #m = name2camel(app.code)
    c = name2camel(service.module)
    custom_controller= "#{c}Controller"
    user_id= session[:user] ? session[:user].id : 0
    Xmain.create :tgel_service_id=>service.id,
      :start=>Time.now,
      :name=>service.name,
      :status=>'I', # init
      :xvars=> {
        :service_id=>service.id, :p=>params,
        :id=>params[:id],
        :user_id=>user_id, :custom_controller=>custom_controller,
        :referer=>request.env['HTTP_REFERER'] }
  end
  def get_default_role(xmain)
    app= xmain.tgel_service.app
    default_role= Role.first :conditions=>{:app_id=>app.id, :code=>'default'}
    return default_role ? default_role.name.to_s : ''
  end
  def create_runseq(xmain)
    @xvars= xmain.xvars
    default_role= get_default_role(xmain)
    xml= xmain.tgel_service.xml
    root = REXML::Document.new(xml).root
    i= 0; j= 0 # i= step, j= form_step
    root.elements.each('node') do |activity|
      action= freemind2action(activity.elements['icon'].attributes['BUILTIN']) if activity.elements['icon']
      i= i + 1
      j= j + 1 if action=='form'
      @xvars[:referer] = activity.attributes['TEXT'] if action=='redirect'
      text= activity.attributes['TEXT']
      if action!= 'if'
        scode, name= text.split(':', 2)
        name ||= scode; name.strip!
        code= name2code(scode)
      else
        code= text
        name= text
      end
      role= get_option_xml("role", activity) || default_role
      runseq= Runseq.create :xmain_id=>xmain.id,
        :name=> name, :action=> action,
        :code=> code, :role=>role.upcase,
        :step=> i, :form_step=> j, :status=>'I',
        :xml=>activity.to_s
      xmain.current_runseq= runseq.id if i==1
    end
    @xvars[:total_steps]= i
    @xvars[:total_form_steps]= j
  end
  def login?
    session[:user] ||= User.find_by_login 'anonymous'
  end
  def active?
    if params[:id] && params[:module].blank?
      xmain= Xmain.find params[:id]
      redirect_to_root unless ['I','R'].include?(xmain.status)
    end
  end
#  def is_public?(app,module_code,service_code)
#    service= TgelService.find :first, :conditions=>['app_id=? AND module=? AND code=?',
#      @app.id, module_code, service_code
#    ]
#    root = REXML::Document.new(service.xml).root
#    first_activity= root.elements['node']
#    !get_option_xml("role", first_activity)
#  end
end
