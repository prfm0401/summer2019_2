class PostImages < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.bigint :user_id
      t.datetime :poat_at
      t.string :file
      t.string :post_text
    end
  end
end
