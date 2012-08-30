class ReArtifactProperties < ActiveRecord::Base
  unloadable

  #attr_accessible :artifact_type

  scope :project_artifact, lambda { |project_id| where(:artifact_type => "Project", :project_id => project_id) } 

  ajaxful_rateable :stars => 10, :allow_update => true#, :dimensions => [:first]

  has_many :comments, :as => :commented, :dependent => :destroy, :order => "created_on asc"

  has_many :realizations, :dependent => :destroy
  has_many :issues, :through => :realizations, :uniq => true

  has_many :user_profiles, 
    :foreign_key => "source_id",
    :class_name => "ReArtifactRelationship",
    :conditions => [ "re_artifact_relationships.relation_type = ?", ReArtifactRelationship::RELATION_TYPES[:dep] ]
    # not need to put :dependent => :destroy, since it will be destroyed through relationships_as_source

  has_many :relationships_as_source,
    :order => "re_artifact_relationships.position",
    :foreign_key => "source_id",
    :class_name => "ReArtifactRelationship",
    :dependent => :destroy

  has_many :relationships_as_sink,
    :order => "re_artifact_relationships.position",
    :foreign_key => "sink_id",
    :class_name => "ReArtifactRelationship",
    :dependent => :destroy

  has_many :traces_as_source,
    :order => "re_artifact_relationships.position",
    :foreign_key => "source_id",
    :class_name => "ReArtifactRelationship",
    :conditions => [ "re_artifact_relationships.relation_type != ?", ReArtifactRelationship::RELATION_TYPES[:pch] ]

  has_many :traces_as_sink,
    :order => "re_artifact_relationships.position",
    :foreign_key => "sink_id",
    :class_name => "ReArtifactRelationship",
    :conditions => [ "re_artifact_relationships.relation_type != ?", ReArtifactRelationship::RELATION_TYPES[:pch] ]

  has_one :parent_relation,
    :order => "re_artifact_relationships.position",
    :foreign_key => "sink_id",
    :class_name => "ReArtifactRelationship",
    :conditions => [ "re_artifact_relationships.relation_type = ?", ReArtifactRelationship::RELATION_TYPES[:pch] ]

  has_many :child_relations,
    :order => "re_artifact_relationships.position",
    :foreign_key => "source_id",
    :class_name => "ReArtifactRelationship",
    :conditions => [ "re_artifact_relationships.relation_type = ?", ReArtifactRelationship::RELATION_TYPES[:pch] ]

  has_many :sinks,    :through => :relationships_as_source, :order => "re_artifact_relationships.position"
  has_many :children, :through => :child_relations, :order => "re_artifact_relationships.position", :source => "sink"

  has_many :sources, :through => :relationships_as_sink,   :order => "re_artifact_relationships.position"
  has_one :parent, :through => :parent_relation, :source => "source"

  has_many :re_bb_data_texts, :dependent => :delete_all
  has_many :re_bb_data_selections, :dependent => :delete_all
  has_many :re_bb_data_artifact_selections, :dependent => :delete_all

  acts_as_event(
    :title => Proc.new { |o|
      "#{l(:re_artifact)} \"#{o.name}\" #{ (o.updated_at == o.created_at)? l(:re_was_created) : l(:re_was_updated) }."
      },
    :description => Proc.new {|o|
        "#{l(:re_artifact)} \"#{o.name}\" #{ (o.updated_at == o.created_at)? l(:re_was_created) : l(:re_was_updated) }."
      },
    :datetime => :updated_at,
    :url => Proc.new {|o|
        { :controller => 're_artifact_properties', :action => 'edit', :id => o.id}
      }
  )

  acts_as_activity_provider(
    :type => 're_artifact_properties',
    :timestamp => "#{ReArtifactProperties.table_name}.updated_at",
    :author_key => "#{ReArtifactProperties.table_name}.updated_by",
    :find_options => {:include => [:project, :user] },
    :permission => :edit_requirements
  )

  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :user, :foreign_key => 'updated_by'

  belongs_to :artifact, :polymorphic => true, :dependent => :destroy

  # attributes= and artifact_attributes are overwritten to instantiate
  # the correct artifact_type and use nested attributes for re_artifact_properties
  accepts_nested_attributes_for :artifact

  def attributes=(attributes = {})
    unless attributes[:artifact_type].blank?
      self.artifact_type = attributes[:artifact_type]
    end
    super
  end

  def artifact_attributes=(attributes)
    artifact = self.artifact_type.constantize.find_or_initilize_by_id(self.artifact_id)
    artifact.attributes = attributes
    self.artifact = artifact
  end

  scope :without_projects, :conditions => ["artifact_type != ?", 'Project']

  scope :of_project, lambda { |project|
    project_id = (project.is_a? Project) ? project.id : project
    { :conditions => { :project_id => project_id } }
  }

  acts_as_watchable
  
  validates :name, :length => { :minimum => 3, :maximum => 50 } 
  validates :project, :presence => true
  validates :created_by, :presence => true
  validates :updated_by, :presence => true
  validates :parent, :presence => true, :unless => Proc.new { |a| a.artifact_type == "Project" }
  validates :artifact_type, :presence => true, :inclusion => {
    :in => ['ReGoal', 'ReSection', 'ReVision', 'ReTask', 'ReSubtask',
      'ReVision', 'reAttachment', 'ReWorkarea', 'ReUserProfile',
      'ReSection', 'ReRequirement', 'ReScenario', 'ReProcessword',
      'ReRational', 'ReUseCase', 'ReRationale'] }

  validates_associated :parent_relation

  after_destroy :delete_wiki_page

  def self.get_properties_id(controllername, subartifact_id)
    # delivers the ID of the re_artifact_properties when the name of the controller and id of sub-artifact is given
    @re_artifact_properties = ReArtifactProperties.find_by_artifact_type_and_artifact_id(controllername.camelize, subartifact_id)
    @re_artifact_properties.id
  end

  # Finds all artifacts that are commonly used by the supplied issues
  def self.find_all_by_common_issues(issue_array, *args)
    artifact_ids = []
    issue_array.each do |issue|
      if artifact_ids.empty?
        artifact_ids = issue.realizations.collect { |r| r.re_artifact_properties_id }
      else
        artifact_ids = artifact_ids & (issue.realizations.collect { |r| r.re_artifact_properties_id })
      end
    end
    ReArtifactProperties.find(artifact_ids, *args)
  end

  def self.available_artifact_types
    all(:group => :artifact_type, :select => :artifact_type).collect(&:artifact_type)
  end

  def position
    return parent_relation.position
  end

  def delete_wiki_page
    wiki_page_name = "#{self.id}_#{self.artifact_type}"
    wiki_page = WikiPage.find_by_title(wiki_page_name)
    wiki_page.destroy if wiki_page
  end

  def gather_children
    # recursively gathers all children for the given artifact
    #
    children = Array.new
    children.concat self.children
    return children if self.children.empty?
    for child in children
      children.concat child.gather_children
    end
    children
  end

end
