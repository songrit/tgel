class TgelLogsController < ApplicationController
  layout "application"
  # GET /tgel_logs
  # GET /tgel_logs.xml
  def index
    @tgel_logs = TgelLog.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tgel_logs }
    end
  end

  # GET /tgel_logs/1
  # GET /tgel_logs/1.xml
  def show
    @tgel_log = TgelLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tgel_log }
    end
  end

  # GET /tgel_logs/new
  # GET /tgel_logs/new.xml
  def new
    @tgel_log = TgelLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tgel_log }
    end
  end

  # GET /tgel_logs/1/edit
  def edit
    @tgel_log = TgelLog.find(params[:id])
  end

  # POST /tgel_logs
  # POST /tgel_logs.xml
  def create
    @tgel_log = TgelLog.new(params[:tgel_log])

    respond_to do |format|
      if @tgel_log.save
        flash[:notice] = 'TgelLog was successfully created.'
        format.html { redirect_to(@tgel_log) }
        format.xml  { render :xml => @tgel_log, :status => :created, :location => @tgel_log }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tgel_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tgel_logs/1
  # PUT /tgel_logs/1.xml
  def update
    @tgel_log = TgelLog.find(params[:id])

    respond_to do |format|
      if @tgel_log.update_attributes(params[:tgel_log])
        flash[:notice] = 'TgelLog was successfully updated.'
        format.html { redirect_to(@tgel_log) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tgel_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tgel_logs/1
  # DELETE /tgel_logs/1.xml
  def destroy
    @tgel_log = TgelLog.find(params[:id])
    @tgel_log.destroy

    respond_to do |format|
      format.html { redirect_to(tgel_logs_url) }
      format.xml  { head :ok }
    end
  end
end
