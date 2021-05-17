require 'rails_helper'
require 'assert_xpath'

RSpec.describe PhotosController, type: :controller do

  include AssertXPath
  render_views  # TODO  real view specs

  describe 'photos/index' do
    it 'contains a link to the new page' do

      get :index  # TODO  upload by copy-n-paste

      #        response.body.should have_selector("title", :content => "Ruby on Rails Sample App |     Home")
      assert_select 'title', text: 'Blog'

      expect(new_photo_path).to eq('/photos/new')
      assert_xpath '//a[ "/photos/new" = @href ]'  #  XPath assertions permit very flexible queries
    end
  end

  describe 'image_to_bounding_boxes' do
    it 'reads text' do
      file_name = 'ocr.jpg'  # TODO  move this file to a fixture folder
      box = image_to_bounding_boxes(file_name)

      expect(box).to eq(
          [%w[32 19 159 70 96 The],
           %w[225 19 219 88 96 quick],
           %w[478 19 245 70 96 brown],
           %w[759 18 125 71 96 fox],
           %w[26 126 313 89 96 jumped],
           %w[377 144 145 52 95 over],
           %w[533 126 181 70 96 the],
           %w[749 127 45 69 96 5],
           %w[37 233 160 89 96 lazy],
           %w[228 233 224 89 95 dogs!]]
        )
    end
  end

end
