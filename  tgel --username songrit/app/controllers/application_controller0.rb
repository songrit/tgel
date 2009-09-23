# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ApplicationHelper
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ec3105b117defb19eb561ade35c3ba34'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  ActiveScaffold.set_defaults do |config|
    config.ignore_columns.add [:created_at, :updated_at, :lock_version]
  end

  def set_app
    @app= App.find_by_code 'dloc'
  end
  def set_songrit(k,v)
    songrit = Songrit.find_by_code k
    songrit = Songrit.new :code=> k unless songrit
    songrit.value= v
    songrit.user_id= session[:user].id
    songrit.save
  end
  def songrit(k, default='')
    songrit = Songrit.find_by_code(k)
    songrit= Songrit.create(:code=>k, :value=>default, :user_id=>session[:user].id) unless songrit
    return songrit.value
  end
  def form2hash(form, object)
    h= {}
    form.each_pair do |k,v|
      next unless k=~/^#{object}_/
      k1= k.sub("#{object}_","")
      h[k1.to_sym]= v
    end
    h
  end
  def redirect_to_root
    redirect_to '/'
  end
  def fork(s)
    if windows?
      system %Q(start ruby script/runner "app = ActionController::Integration::Session.new; app.get '#{s}'" /LOW )
    else
      system %Q(ruby script/runner "app = ActionController::Integration::Session.new; app.get '#{s}'"  & )
    end
  end
  def check_wait(runseq=@runseq)
    wait= get_option('wait', runseq)
    if wait
      xvars= runseq.xmain.xvars
      return xvars[name2code(wait).to_sym] ? false : true
    else
      return false
    end
  end
  def role_name(code)
    Role.find_by_code(code).name
  end
  def affirm(s)
    s =~ /[y|yes|t|true]/i
  end
  def negate(s)
    s =~ /[n|no|f|false]/i
  end
  
  # method นี้เจ๋งจริงๆ
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
  def win32?
        !(RUBY_PLATFORM =~ /win32/).nil?
  end
  def http_chaiyo(href)
    require "net/http"
    require "ostruct"
    proxy = ENV["http_proxy"] ? URI.parse(ENV["http_proxy"]) : OpenStruct.new
    url = URI.parse(href)
    req = Net::HTTP::Get.new(url.path+'?'+url.query)
    res = Net::HTTP::Proxy(proxy.host,proxy.port,proxy.user,proxy.password).start(url.host, url.port) do |http|
      http.request(req)
    end
    res.body
  end
  def http_chaiyo2(href) # chaiyo2
    require 'net/http'
    url = URI.parse(href)
    req = Net::HTTP::Get.new(url.path+'?'+url.query)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    res.body 
  end
  def http_nares(href)
    require "net/http"
    require "uri"
    url = URI.parse(href)
    resp= ''
    Net::HTTP.start(url.host, url.port) { |http|
      resp = http.get(url.path)
    }
    resp.body
  end
  def http(href)
    require 'open-uri'
    open(href).read
  end
  def http_songrit(arg)
    hostport = arg.scan(/http:\/\/(.+?)\//)
    host, port = $1.split(/:/)
    port ||= "80"
    uri = arg.scan(/http:\/\/.+?(\/.+)/)
    begin
      h = Net::HTTP.start(host, port)
      head, f = h.get(uri)
      result= f
    rescue Timeout::Error
      result= "timeout error"
    end
    result
  end
  def name2camel(s)
    s.gsub(' ','_').camelcase
  end
  def freemind2action(s)
    case s
    when 'bookmark'
      'call'
    when 'attach'
      'form'
    when 'wizard'
      'ws'
    when 'help'
      'if'
    when 'forward'
      'redirect'
    when 'kaddressbook'
      'redirect' # end job and redirect
    end
  end
  def listed(node)
    edge= node.elements["edge"]
    return edge ? node.elements["edge"].attributes["WIDTH"] != "thin" : true
  end
  def name2code(s)
    code, name = s.split(':')
    code.downcase.strip.gsub(' ','_').gsub(/[^_a-zA-Z0-9]/,'')
  end
  def model2hash(n)
    h= Hash.new
    n.each_element('node') do |nn|
      next if nn.attributes['TEXT'] =~ /\#.*/
      k,v= nn.attributes['TEXT'].split(/:\s*/,2)
      v ||= 'integer'
      h[k.to_sym]= v
    end
    h
  end
  def run_ruby(s)
      if windows?
        system %Q( start /LOW #{s}  )
      else
        system %Q(#{s} & )
      end
  end
  def exec_cmd(s)
    cmd= ExecCmd.new(s)
    cmd.run
    cmd.output
  end
  def model_exists?(model)
    File.exists? File.join(RAILS_ROOT,'app/models', model + '.rb')
  end
  def controller_exists?(app, modul)
    File.exists? File.join(RAILS_ROOT,"app/controllers/#{app}/#{modul}_controller.rb")
  end
#  def svn_update_tgel
#    #tgel_dir= File.join(File.dirname(__FILE__), '../../tgel')
#    cmd= ExecCmd.new("svn update tgel")
#    cmd.run
#    cmd
#  end
  def tis620(t)
    cd = Iconv.new("TIS-620", "UTF-8")
    cd.iconv(t)
  end
  def utf8(t)
    cd = Iconv.new("UTF-8", "TIS-620")
    cd.iconv(t)
  end
  def get_xvars
    @runseq= Runseq.find($runseq_id)
    @xmain= @runseq.xmain
    @xvars= @xmain.xvars
  end
  def save_xvars
    @xmain.xvars= @xvars
    @xmain.save
  end
end

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
