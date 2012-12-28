class PictureContestEntry < ActiveRecord::Base
  belongs_to :contest, :foreign_key => :picture_contest_id, :class_name => "PictureContest"
  belongs_to :picture
end