require 'spec_helper'

describe User, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @title = 'New folder'
  end

  context 'add feed to new folder' do

    it 'creates new folder' do
      @user.move_feed_to_folder @feed, folder_title: @title

      @user.reload
      @user.folders.where(title: @title).should be_present
    end

    it 'adds feed to new folder' do
      @user.move_feed_to_folder @feed, folder_title: @title
      @user.reload

      folder = @user.folders.where(title: @title).first
      folder.feeds.count.should eq 1
      folder.feeds.should include @feed
    end

    it 'removes feed from its old folder' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      folder.feeds.count.should eq 1
      @user.move_feed_to_folder @feed, folder_title: @title
      folder.feeds.count.should eq 0
    end

    it 'deletes old folder if it has no more feeds' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      @user.move_feed_to_folder @feed, folder_title: @title
      Folder.exists?(folder).should be_false
    end

    it 'does not delete old folder if it has more feeds' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      folder.feeds << @feed << feed2

      @user.move_feed_to_folder @feed, folder_title: @title
      Folder.exists?(folder).should be_true
    end

    it 'returns the new folder' do
      folder = @user.move_feed_to_folder @feed, folder_title: @title
      folder.user_id.should eq @user.id
      folder.title.should eq @title
    end

    it 'raises an error if the user already has a folder with the same title' do
      folder = FactoryGirl.build :folder, user_id: @user.id, title: @title
      @user.folders << folder
      expect {@user.move_feed_to_folder @feed, folder_title: @title}.to raise_error FolderAlreadyExistsError
    end

    it 'does not raise an error if another user has a folder with the same title' do
      user2 = FactoryGirl.create :user
      folder2 = FactoryGirl.build :folder, user_id: user2.id, title: @title
      user2.folders << folder2

      expect {@user.move_feed_to_folder @feed, folder_title: @title}.to_not raise_error
    end

    it 'raises an error if user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.move_feed_to_folder feed2, folder_title: @title}.to raise_error NotSubscribedError
    end
  end
end