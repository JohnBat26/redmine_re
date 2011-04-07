class ReWorkareaController < RedmineReController
  unloadable
  def index
  
    @re_workareas = ReWorkarea.find(:all,
                         :joins => :re_artifact_properties,
                         :conditions => {:re_artifact_properties => {:project_id => @project.id}}
    )
    render :layout => false if params[:layout] == 'false'
  end

  def new
    # redirects to edit to be more dry

    redirect_to :action => 'edit', :project_id => params[:project_id]
  end

  def edit
    @re_workarea = ReWorkarea.find_by_id(params[:id], :include => :re_artifact_properties) || ReWorkarea.new
    @project ||= @re_workarea.project
    
    # render html for tree
    @html_tree = create_tree
    
    if request.post?
      @re_workarea.attributes = params[:re_workarea]
      add_hidden_re_artifact_properties_attributes @re_workarea

      flash[:notice] = t(:re_workarea_saved) if save_ok = @re_workarea.save

      redirect_to :action => 'edit', :id => @re_workarea.id and return if save_ok
    end
  end

  def delete
  # deletes and updates the flash with either success, id not found error or deletion error
    @re_workarea = ReWorkarea.find_by_id(params[:id], :include => :re_artifact_properties)
    if !@re_workarea
      flash[:error] = t(:re_workarea_not_found, :id => params[:id])
    else
      name = @re_workarea.name
      if ReWorkarea.destroy(@re_workarea.id)
        flash[:notice] = t(:re_workarea_deleted, :name => name)
      else
        flash[:error] = t(:re_workarea_not_deleted, :name => name)
      end
    end
    redirect_to :controller => 'requirements', :action => 'index', :project_id => @project.id
  end

end