require_dependency 'issue'


#Mixin for Issue Model
#Connects a Redmine Issue with an RE-Plugin Artifact


module IssuePatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    #typing in class
    base.class_eval do
      unloadable

      #puts base.methods
      has_many :realizations
      has_many :re_artifact_properties,  :through => :realizations, :uniq => true

    end

  end


module ClassMethods
end

module InstanceMethods
end

end

Issue.send(:include, IssuePatch)