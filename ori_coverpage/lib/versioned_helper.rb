module VersionedHelper

  def revert_path(versionable, version = 1)
    version_number = (version.is_a?(VestalVersions::Version) ? version.number : 1)
    eval("revert_to_version_#{pname}_path(versionable, :version_number => version_number)")
  end

  def revert_link(versionable, version = 1)
    version_number = (version.is_a?(VestalVersions::Version) ? version.number : 1)
    if versionable.version == 1 || versionable.version == version_number || versionable.changes_between(version_number, versionable.version).empty?
      image_tag('buttons/admin/restore-off.gif', :alt => "Version #{version_number} is identical to the current version", :title => 'This version is identical to the current version')
    else
      link_to(image_tag('buttons/admin/restore.gif', :alt => 'Restore'), revert_path(versionable, version), :method => :post, :title => "Restore to version #{version_number}")
    end
  end
  
  def compare_link(versionable, version = 1)
    version_number = (version.is_a?(VestalVersions::Version) ? version.number : 1)
    if versionable.version == version_number || versionable.changes_between(version_number, versionable.version).empty?
      image_tag('buttons/admin/compare-off.gif', :alt => "Version #{version_number} is identical to the current version", :title => 'This version is identical to the current version')
    else
      link_to(image_tag('buttons/admin/compare.gif', :alt => 'Compare'), { :action => "compare", :version_number => version_number }, { :method => :post, :remote => true}, {:title => "Compare version #{version_number} to current version"})
    end
  end
  
  def changeset_link(versionable, version = 1)
    version_number = (version.is_a?(VestalVersions::Version) ? version.number : 1)
    if version_number == 1 || version.changes.empty?
      image_tag('buttons/admin/compare-off.gif', :alt => 'Changeset', :title => "Version #{version_number} changeset is empty")
    else
      link_to(image_tag('buttons/admin/compare.gif', :alt => 'Changeset'), { :action => "changeset", :version_number => version_number }, { :method => :post, :remote => true}, {:title => "View changeset of this version #{version_number}"})
    end
  end
  
end
