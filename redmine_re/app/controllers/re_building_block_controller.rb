class ReBuildingBlockController < RedmineReController
  unloadable
  menu_item :re


  def new
    redirect_to :action => 'edit', :project_id => params[:project_id], :artifact_type => params[:artifact_type]
  end
  
  def update_config_form
    @artifact_type = params[:artifact_type]
    @re_building_block = ReBuildingBlock.find_by_id(params[:id]) || ReBuildingBlock.new
    # renders the rjs-Template with the same name
  end
  
  def react_to_change_in_field_multiple_values
    @artifact_type = params[:artifact_type]
    @re_building_block = ReBuildingBlock.find_by_id(params[:id]) || ReBuildingBlock.new
    # renders the rjs-Template with the same name
  end
  
  def react_to_change_in_field_referred_artifact_types
    @artifact_type = params[:artifact_type]
    @re_building_block = ReBuildingBlock.find_by_id(params[:id]) || ReBuildingBlock.new
    # renders the rjs-Template with the same name
  end
  
  def react_to_change_in_data_field_artifact_type
    artifact_type = params[:artifact_type]
    @artifact = artifact_type.camelcase.constantize.find_by_id(params[:id], :include => :re_artifact_properties) || artifact_type.camelcase.constantize.new
    @artifact_type = artifact_type
    render :update do |page|   
      page["re_bb_#{params[:re_bb_id]}_data_field_artifact_type_selection".to_sym].replace_html :partial => "re_building_block/re_bb_artifact_selection/data_field_artifact_type_selection", :selected_type => params[:selected_type], :params_path_artifact => params[:params_path_artifact]
    end
  end
  
  
  def edit
   @re_building_block = ReBuildingBlock.find_by_id(params[:id]) || ReBuildingBlock.new
   @project = Project.find(params[:project_id])
   @artifact_type = params[:artifact_type]
   # Check for ArtifactSelectionBuildingBlock if one selected artifact is choosen already
   if ! @re_building_block.referred_artifact_types.nil? and @re_building_block.referred_artifact_types.count == 1
     @artifact_selected = @re_building_block.referred_artifact_types.first.camelcase
   else
     @artifact_selected = nil
   end
   if request.post?
      params[:re_building_block][:artifact_type] = params[:artifact_type]
      # Test if @re_builing_block is a new object
      @re_building_block = params[:type].constantize.new if @re_building_block.artifact_type.nil?
      @re_building_block.attributes = params[:re_building_block]
      # Set new postion of building block if new object
      @re_building_block.position = get_new_position(@artifact_type) if @re_building_block.new_record?
      @re_building_block = ReBuildingBlock.additional_work_before_save(@re_building_block, params)
      flash[:notice] = t(:re_bb_saved) if save_ok = @re_building_block.save
      # Calling the strategies for handling additional work after normal saving
      ReBuildingBlock.additional_work_after_save(@re_building_block, params)
      redirect_to :action => 'edit', :id => @re_building_block.id, :building_block => @re_building_block, :building_block_type => params[:type].underscore, :artifact_type => params[:artifact_type], :project_id => @project.id and return if save_ok
   end
 end
 
 def delete_data
   bb = ReBuildingBlock.find(params[:re_bb_id])
   datum = bb.get_data_class_name.constantize.find(params[:re_bb_data_id])
   @artifact = ReArtifactProperties.find(datum.re_artifact_properties_id)
   @artifact_type = @artifact.artifact_type   
   datum.delete unless datum.nil?
   bb_error_hash = {} 
   bb_error_hash = ReBuildingBlock.validate_building_blocks(@artifact, bb_error_hash)
   data = bb.find_my_data(@artifact)
   if data.count <= 1 and ! bb.multiple_values
     partial = bb.data_form_partial_strategy
   else
     partial = bb.multiple_data_form_partial_strategy
   end
   render :partial => partial, :locals => {:re_bb => bb, :data => data, :bb_error_hash => bb_error_hash}
 end
 
 #######
 private
 #######
 
 def get_new_position(artifact_type)
   my_bbs = ReBuildingBlock.find_bbs_of_artifact_type(artifact_type)
   my_bbs.last.position + 1 
 end

end