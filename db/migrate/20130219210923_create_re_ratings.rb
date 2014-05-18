class CreateReRatings < ActiveRecord::Migration
  def change
    create_table :re_ratings do |t|
      t.string :user_id
      t.string :re_artifact_properties_id
      t.integer :value
    end
  end
end
