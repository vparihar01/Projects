class CreateStreamings < ActiveRecord::Migration
  def change
    create_table :streamings do |t|
      t.string :video_name
      t.string :duration
      t.string :length
      t.string :string

      t.timestamps
    end
  end
end
