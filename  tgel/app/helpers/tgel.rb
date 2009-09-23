module TgelMethods
  def non_fork?(s)
#    %w(call ws redirect invoke).include? s
    return false
  end
  def ui_action?(s)
    %w(form output).include? s
  end
  def fork_action?(s)
    !non_fork?(s)
  end
  def utf8_bom
    utf8_arr=[0xEF,0xBB,0xBF]
    utf8_str = utf8_arr.pack("c3")
    return utf8_str
  end
  def tgel_comment?(s)
    s[0]==35
  end
  def redirect_to_root
    redirect_to root_path
  end
  def root_path
    root+"/"
  end
  def root
    ENV['RAILS_RELATIVE_URL_ROOT'] || ""
  end
  def tgel_log(log_type, message)
    # remove params[:password] before log
    log_params= params
    log_params[:password]= nil
    TgelLog.create :log_type=>log_type, :message=>message, :tgel_user_id=>session[:user_id],
      :session=>session, :params=>log_params, :controller=>params[:controller],
      :action=>params[:action]
  end
  def exec_cmd(s)
    cmd= ExecCmd.new(s)
    cmd.run
    cmd.output
  end
  def link_view_mm(msg)
    "<a href='#{root}/tgel/view_mm'>#{msg}</a>"
  end
  def file_asset_id(source)
    asset_id= ENV["RAILS_ASSET_ID"] ||
      File.mtime("#{RAILS_ROOT}/public/#{source}").to_i.to_s rescue ""
    #source << '?' + asset_id
    image_path "../#{source}?#{asset_id}"
  end
  def http(href)
    require 'open-uri'
    open(href).read
  end
  def date_select_thai(object, method)
    date_select object, method, :use_month_names=>MONTHS, :order=>[:day, :month, :year]
  end
#  def step(s, total) # graphic background
#    s = (s==0)? 1: s.to_i
#    total = total.to_i
#    out =[]
#    (s-1).times {|ss| out << "<span class='step_done' >#{ss+1}</span>" }
#    out << "<span class='step_now' >#{s}</span>"
#    for i in s+1..total
#      out << "<span class='step_more' >#{i}</span>"
#    end
#    text=""
#    out.each_with_index do |item, index|
#      text << item
#      text << "<br/>" if ((index+1)%7==0 && index!=0)
#    end
#    text
#  end
  def step(s, total) # square text
    s = (s==0)? 1: s.to_i
    total = total.to_i
    out ="<div class='step'>"
    (s-1).times {|ss| out += "<span class='steps_done'>#{(ss+1)}</span>" }
    out += %Q@<span class='step_now' >@
    out += s.to_s
    out += "</span>"
    out += %Q@@
    for i in s+1..total
      out += "<span class='steps_more'>#{i}</span>"
    end
    out += "</div>"
  end
#  def step(s, total) # Wingdings text
#    s = (s==0)? 1: s.to_i
#    total = total.to_i
#    out = %Q(<div class='step' style="font: 72pt 'Wingdings 2';">)
#    (s-1).times {|ss| out += (117+ss).chr }
#    out += %Q@<span style="color:red;">@
#    out += (116+s).chr
#    out += "</span>"
#    for i in s...total
#      out += (106+i).chr
#    end
#    out += "</div>"
#  end

  def win32?
        !(RUBY_PLATFORM =~ /win32/).nil?
  end
  def nbsp(n)
    "&nbsp;"*n
  end
  def role_name(code)
    role= TgelRole.find_by_code(code)
    return role ? role.name : ""
  end
  def authorize? # use in pending tasks
    @runseq= @xmain.tgel_runseqs.find(:first, :order=>'step', :conditions=>"status != 'F'")
    return false unless @runseq
    return false unless eval(@runseq.rule) if @runseq.rule
    return true unless fork_action?(@runseq.action)
    return true if @runseq.role.blank? && !check_wait
    user= get_user
    return false unless user
#    return false if user.role.blank?
    has_role = user.role.upcase.split(',').include?(@runseq.role.upcase) && !check_wait
#    has_role = user.role.upcase.split(',').include?(@runseq.role.upcase)
    until @runseq && (has_role || !affirm(get_option("fork")))
      break unless @runseq
      step= @runseq.step
      @runseq= @xmain.tgel_runseqs.find(
        :first, :conditions=>["step> ? AND status!=?",step, 'F'], :order=>:step)
#      next if @runseq && @runseq.status=='F'
      if @runseq
#        has_role = (@runseq.role.blank? || user.role.upcase.split(',').include?(@runseq.role.upcase))
        has_role = (@runseq.role.blank? || user.role.upcase.split(',').include?(@runseq.role.upcase)) && !check_wait
      else
        has_role = false
      end
    end
    has_role
  end
  def authorize_init? # use when initialize new transaction
    xml= @service.xml
    step1 = REXML::Document.new(xml).root.elements['node']
    role= get_option_xml("role", step1) || ""
#    rule= get_option_xml("rule", step1) || true
    return true if role==""
    user= get_user
    unless user
      return role.blank?
    else
      return false unless user.role
      return user.role.upcase.split(',').include?(role.upcase)
    end
  end
  def check_wait(runseq=@runseq)
    xml= REXML::Document.new(runseq.xml).root
    wait=[]
    xml.each_element('///node') do |n|
      text= n.attributes['TEXT']
      if text =~ /wait/i
        n.elements.each("node") do |nn|
          wait << nn.attributes['TEXT']
        end
      end
    end
    done= true
    unless wait.blank?
      wait.each do |w|
        runseq= @xmain.tgel_runseqs.find_by_code w
        if runseq
          done= false unless runseq.status=='F'
        else
          tgel_log("ERROR","check_wait: cannot find runseq.code='#{w}'")
        end
      end
    end
    !done
  end
#  def check_wait(runseq=@runseq)
#    wait= get_option('wait', runseq)
#    if wait
#      xvars= runseq.tgel_xmain.xvars
#      return xvars[wait.to_sym] ? false : true
#    else
#      return false
#    end
#  end
  def get_ip
    request.env['HTTP_X_FORWARDED_FOR'] || request.env['REMOTE_ADDR']
  end
  def get_option(opt, runseq=@runseq)
    xml= REXML::Document.new(runseq.xml).root
    url=''
    xml.each_element('///node') do |n|
      text= n.attributes['TEXT']
      url= text if text =~/^#{opt}:\s*/
    end
    c, h= url.split(':', 2)
    opt= h ? h.strip : false
  end
  alias_method :get_option_runseq, :get_option
  def get_option_xml(opt, xml)
    #xml= REXML::Document.new(runseq.xml).root
    url=''
    xml.each_element('node') do |n|
      text= n.attributes['TEXT']
      url= text if text =~/^#{opt}:\s*/
    end
    c, h= url.split(':', 2)
    opt= h ? h.strip : false
  end
  def get_mm_links(runseq=@runseq)
    xml= REXML::Document.new(runseq.xml).root
    url=[]
    xml.each_element('///node') do |n|
      text= n.attributes['TEXT']
      next unless text =~/^link/i
      n.each_element('node') do |nn|
        if nn.elements['node']
          link_url= nn.elements['node'].attributes['TEXT']
          link_text = nn.attributes['TEXT']
          tip= link_url
        else
          link_url= root_path
          link_text = "#{nn.attributes['TEXT']}"
          tip= "<span style='color:red'>warning: no link specified in mindmap</span>"
        end
        url<< {:text=>link_text, :url=> link_url, :tip=> tip}
      end
    end
    url
  end
  def get_default_role
    default_role= TgelRole.find_by_code 'default'
    return default_role ? default_role.name.to_s : ''
  end
  def xml_text(s)
    html_escape(s).gsub("\n","<br/>")
  end
  def get_app
    findex= "#{RAILS_ROOT}/index.mm"
    fmain= "#{RAILS_ROOT}/main.mm"
    if File.exists?(findex)
      f= findex
    elsif File.exists?(fmain)
      f= fmain
    else
      return nil
    end
    #f= "#{RAILS_ROOT}/main.mm"
    t= REXML::Document.new(File.read(f).gsub("\n","")).root
    recheck= true ; first_pass= true
    while recheck
      recheck= false
      t.elements.each("//node") do |n|
        if n.attributes['LINK'] # has attached file
          if first_pass
            f= "#{RAILS_ROOT}/#{n.attributes['LINK']}"
          else
            f= n.attributes['LINK']
          end
          next unless File.exists?(f)
          tt= REXML::Document.new(File.read(f).gsub("\n","")).root.elements["node"]
          make_folders_absolute(f,tt)
          tt.elements.each("node") do |tt_node|
            n.parent.insert_before n, tt_node
          end
          recheck= true
          n.parent.delete_element n
        end
        if smile?(n) # has attached file
          if first_pass
            f= "#{RAILS_ROOT}/#{n.attributes['TEXT']}.mm"
          else
            f= "#{n.attributes['TEXT']}.mm"
          end
          next unless File.exists?(f)
          tt= REXML::Document.new(File.read(f).gsub("\n","")).root.elements["node"]
          make_folders_absolute(f,tt)
          tt.elements.each("node") do |tt_node|
            n.parent.insert_before n, tt_node
          end
          recheck= true
          n.parent.delete_element n
        end
      end
      first_pass = false
    end
    t
  end
  def make_folders_absolute(f,tt)
    # inspect all nodes that has attached file (2 cases) and replace relative path with absolute path
    tt.elements.each("//node") do |nn|
      if smile?(nn)
        nn.attributes['TEXT']= File.expand_path(File.dirname(f))+"/#{nn.attributes['TEXT']}"
      end
      if nn.attributes['LINK']
        nn.attributes['LINK']= File.expand_path(File.dirname(f))+"/#{nn.attributes['LINK']}"
      end
    end
  end
  def smile?(n)
    # check to see if node has smile icon which indicates file attachment
    n.elements["icon"] && n.elements["icon"].attributes["BUILTIN"]=="ksmiletris"
  end
  def get_service(s)
    m,c= s.split("/")
    TgelService.first :conditions=>["module= ? AND code= ?", m,c]
  end
  def get_user
    return nil unless session
    return session[:user_id] ? TgelUser.find(session[:user_id]) : nil
  end

  alias_method(:current_user, :get_user)

  def name2code(s)
    # rather not ignore # symbol cause it could be comment
    code, name = s.split(':')
    code.downcase.strip.gsub(' ','_').gsub(/[^#_\/a-zA-Z0-9]/,'')
  end
  def name2camel(s)
    s.gsub(' ','_').camelcase
  end
  def model_exists?(model)
    File.exists? "#{RAILS_ROOT}/app/models/#{model}.rb"
  end
  def controller_exists?(modul)
    File.exists? "#{RAILS_ROOT}/app/controllers/#{modul}_controller.rb"
  end
  def make_fields(n)
    f= ""
    n.each_element('node') do |nn|
      next if nn.attributes['TEXT'] =~ /\#.*/
      k,v= nn.attributes['TEXT'].split(/:\s*/,2)
      v ||= 'integer'
      v= 'float' if v=~/double/i
      f << " #{name2code(k.strip)}:#{v.strip} "
    end
    f
  end
#  def make_fields(n)
#    f= ""
#    n.each_element('node') do |nn|
#      next if nn.attributes['TEXT'] =~ /\#.*/
#      k,v= nn.attributes['TEXT'].split(/:\s*/,2)
#      v ||= 'integer'
#      f << "      t.#{v.strip} :#{name2code(k.strip)}\n"
#    end
#    f
#  end
  def listed(node)
    edge= node.elements["edge"]
    return edge ? node.elements["edge"].attributes["WIDTH"] != "thin" : true
  end
  def freemind2action(s)
    case s
    when 'bookmark' # Excellent
      'call'
    when 'attach' # Look here
      'form'
    when 'wizard' # Magic
      'ws'
    when 'help' # Question
      'if'
    when 'forward' # Forward
      'redirect'
    when 'kaddressbook' #Phone
      'invoke' # invoke new service along the way
    when 'pencil'
      'output'
    end
  end
  def affirm(s)
    s =~ /[y|yes|t|true]/i
  end
  def negate(s)
    s =~ /[n|no|f|false]/i
  end
  def get_xvars
    @runseq= TgelRunseq.find($runseq_id)
    @xmain= @runseq.tgel_xmain
    @xvars= @xmain.xvars
  end
  def save_xvars
    @xmain.xvars= @xvars
    @xmain.save
  end
  # no longer needed because TgelMethod added to application_controller from template
#  def add_tgel_to_controller(m)
#    f= Rails.root.join('app', 'controllers', "#{m}_controller.rb")
#    s = <<-EOT
#class #{m.camelcase}Controller < ApplicationController
#  require "tgel"
#  include TgelMethods
#  # add get_xvars or save_xvars if you'd like to use @xvars in each method
#    EOT
#    orig= File.read(f)
#    ss = orig.sub("class #{m.camelcase}Controller < ApplicationController", s)
#    File.open(f, 'w') { |ff| ff << ss }
#  end
  def date_thai(d= Time.now, options={})
    y = d.year+543
    if options[:monthfull]
      mh= ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฏาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม']
    else
      mh= ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.']
    end
    if options[:date_only]
      d.day.to_s+" "+mh[d.month-1]+" "+y.to_s
    else
      d.day.to_s+" "+mh[d.month-1]+" "+y.to_s+" เวลา "+sprintf("%02d",d.hour.to_s)+":"+sprintf("%02d",d.min.to_s)
    end
  end
  def tis620(t)
    cd = Iconv.new("TIS-620", "UTF-8")
    cd.iconv(t)
  end
  def utf8(t)
    cd = Iconv.new("UTF-8", "TIS-620")
    cd.iconv(t)
  end
  def set_songrit(k,v)
    songrit = TgelSongrit.find_by_code k
    songrit = TgelSongrit.new :code=> k unless songrit
    songrit.value= v
    if session && session[:user_id]
      songrit.tgel_user_id= session[:user_id]
    end
    songrit.save
  end
  def songrit(k, default='')
    songrit = TgelSongrit.find_by_code(k)
    songrit= TgelSongrit.create(:code=>k, :value=>default, :tgel_user_id=>session[:user]) unless songrit
    return songrit.value
  end
end

#class Object
#  def set_songrit(k,v)
#    songrit = TgelSongrit.find_by_code k
#    songrit = TgelSongrit.new :code=> k unless songrit
#    songrit.value= v
#    if session[:user_id]
#      songrit.tgel_user_id= session[:user_id]
#    end
#    songrit.save
#  end
#  def songrit(k, default='')
#    songrit = TgelSongrit.find_by_code(k)
#    songrit= TgelSongrit.create(:code=>k, :value=>default, :tgel_user_id=>session[:user]) unless songrit
#    return songrit.value
#  end
#end

class ExecCmd
  attr_reader :output,:cmd,:exec_time
  #When a block is given, the command runs before yielding
  def initialize cmd
    @cmd=cmd
    @cmd_run=cmd+" 2>&1" unless cmd=~/2>&1/
    if block_given?
      run
      yield self
    end
  end
  #Runs the command
  def run
    t1=Time.now
    IO.popen(@cmd_run){|f|
      @output=f.read
      @process=Process.waitpid2(f.pid)[1]
    }
    @exec_time=Time.now-t1
  end
  #Returns false if the command hasn't been executed yet
  def run?
    return false unless @process
    return true
  end
  #Returns the exit code for the command. Runs the command if it hasn't run yet.
  def exitcode
    run unless @process
    @process.exitstatus
  end
  #Returns true if the command was succesfull.
  #
  #Will return false if the command hasn't been executed
  def success?
    return @process.success? if @process
    return false
  end
end

class String
  def comment?
    self[0]==35 # check if first char is #
  end
end

module ActionView
  module Helpers
    class FormBuilder
      def point(o={:lat=>13.74889, :lng=>100.49503, :zoom=>11, :width=>'500px', :height=>'300px'})
        text = <<-EOT
          <script type='text/javascript'>
          //<![CDATA[
          function GLoad() {
            if (GBrowserIsCompatible()) {
              var map_#{self.object_name} = new GMap2(document.getElementById("map_#{self.object_name}"));
              var point = new GLatLng(#{o[:lat]}, #{o[:lng]});
              map_#{self.object_name}.setCenter(point, #{o[:zoom]});
              map_#{self.object_name}.addControl(new GSmallMapControl());
              map_#{self.object_name}.addControl(new GMapTypeControl());
              var marker = new GMarker(point);
              map_#{self.object_name}.addOverlay(marker);
              GEvent.addListener(map_#{self.object_name}, "click", function(overlay, latlng) {
                map_#{self.object_name}.clearOverlays();
                var marker = new GMarker(latlng);
                map_#{self.object_name}.addOverlay(marker);
                $('#waypoint_lat').val(latlng.y);
                $('#waypoint_lng').val(latlng.x);
              })
            }
          }
          //]]>
          </script>
          Latitude: #{self.text_field :lat, :size=>20}
          Longitude: #{self.text_field :lng, :size=>20}
          <br/>
          <div id='map_#{self.object_name}' style='width:#{o[:width]}; height:#{o[:height]};'></div>
        EOT
      end
    end
  end
end
