class RemoveLanguageAbbrFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :language_abbr
  end

  def self.down
    add_column :content_pages, :language_abbr, :string
  end
end
