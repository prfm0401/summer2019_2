class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.bigint :post_id
      t.string :text
      t.datetime :comment_at
    end
  end
end
