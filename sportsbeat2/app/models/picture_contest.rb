class PictureContest < Contest
  has_many :entries, :class_name => "PictureContestEntry", :dependent => :destroy
end