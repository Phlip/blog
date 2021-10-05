require 'spec_helper'

class Home
  include Capybara::DSL

  def visit_homepage
    visit('http://localhost:3000/messages')
  end

end

feature "Visit homepage" do

  let(:home) {Home.new}

  scenario "Able to see text, Word Nerds", :js => true do
    home.visit_homepage
    expect(page).to have_content("Chat")
  end

end