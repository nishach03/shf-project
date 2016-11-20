class AddMembershipApplicationRefToUploadedFiles < ActiveRecord::Migration[5.0]
  def change
    add_reference :uploaded_files, :membership_application, index: true, foreign_key: true
  end
end
