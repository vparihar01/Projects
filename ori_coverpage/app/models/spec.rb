class Spec < ActiveRecord::Base   
  belongs_to :specable, :polymorphic => true
  
	# Validation
	validates :name, :presence => true
  validates :contact_name, :presence => true
  validates :contact_email, :presence => true
	
  def inclusions
    { :tests => 'Accelerated Reader Tests', 
      :kits => 'Catalog Card Kits', 
      :readinglabels => 'Reading Program Labels', 
      :disk => 'Data Disk', 
      :labels => 'Barcode Labels' }.collect do |field, label|
      self.send("include_#{field}?") ? label : nil  
    end.compact
  end
  	
	CARDS_VALUES = {
		'Complete Set' => 'complete',
	}.freeze
		
	POCKETS_VALUES = {
		'Back Flyleaf' => 'back-flyleaf',
		'Front Flyleaf' => 'front-flyleaf',
		'Inside Back Cover' => 'inside-back-cover',
		'Inside Front Cover' => 'inside-front-cover',
		'Unattached' => 'unattached',
	}.freeze
	
	LABELS_VALUES = {
		'Attached (2" from bottom)' => 'attached',
		'Unattached' => 'unattached',
	}.freeze
		
	ARLABELS_VALUES = {
		'Attached above Spine Label' => 'attached',
		'Unattached' => 'unattached',
	}.freeze
		
	DISKSOFTWARE_VALUES = {
		'Alexandria' => 'alexandria',
		'Athena' => 'athena',
		'Circulation Plus' => 'circulation-plus',
		'Dynix' => 'dynix',
		'Follett' => 'follett',
		'Horizon' => 'horizon',
		'Mandarin' => 'mandarin',
		'Sirsi' => 'sirsi',
		'Spectrum' => 'spectrum',
		'Unison' => 'unison',
		'Winnebago' => 'winnebago',
	}.freeze
		
	RECORDFORMAT_VALUES = {
	  'Pre 1991 MicroLIF Format' => 'pre-1991-microlif',
	  '1991 USMARC MicroLIF Format - 852 Holdings' => '1991-microlif-852',
	  '1991 USMARC MicroLIF Format - 949 Holdings' => '1991-microlif-949',
	}.freeze
	
	MEDIAFORMAT_VALUES = {
		'IBM Compatible' => 'ibm',
		'Macintosh' => 'macintosh',
	}.freeze
	
	MEDIATYPE_VALUES = {
		'CD-ROM' => 'cdrom',
		'3.5 inch floppy' => 'floppy',
		'E-mail' => 'email',
	}.freeze
	
	SYMBOLOGY_VALUES = {
		'Code 39 (Code 3 of 9)' => 'code39',
		'Code 39 MOD 10 (13 plus check digit)' => 'code-39-mod10',
		'Code 39 MOD 43 (13 plus check digit)' => 'code-39-mod43',
		'Codabar (13 plus check digit)' => '14-digit-codabar',
		'Codabar without check digit' => '13-digit-codabar',
		'Follett 2 of 5 (T)' => 'follett-2of5',
		'Interleave 2 of 5' => 'interleave-2of5',
	}.freeze
		
	LOCATION_VALUES = {
		'Outside Front Cover' => 'outside-front-cover',
		'Inside Front Cover' => 'inside-front-cover',
		'Front Flyleaf' => 'front-flyleaf',
		'Back Flyleaf' => 'back-flyleaf',
		'Outside Back Cover' => 'outside-back-cover',
		'Inside Back Cover' => 'inside-back-cover',
		'On Book Pocket' => 'bookpocket',
		'Unattached' => 'unattached',
	}.freeze
		
	POSITION_VALUES = {
		'Upper Left' => 'upper-left',
		'Upper Middle' => 'upper-middle',
		'Upper Right' => 'upper-right',
		'Middle Left' => 'middle-left',
		'Middle Middle' => 'middle-middle',
		'Middle Right' => 'middle-right',
		'Lower Left' => 'lower-left',
		'Lower Middle' => 'lower-middle',
		'Lower Right' => 'lower-right',
	}.freeze
	
	ORIENTATION_VALUES = {
		'Horizontal' => 'horizontal',
		'Vertical Reading Top to Bottom' => 'vertical-reading-top-bottom',
		'Vertical Reading Bottom to Top' => 'vertical-reading-bottom-top',
	}.freeze
  
end
