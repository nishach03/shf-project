class CreateBusinessCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :business_categories do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end