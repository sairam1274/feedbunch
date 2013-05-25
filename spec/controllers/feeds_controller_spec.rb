require 'spec_helper'

describe FeedsController do

  before :each do
    @user = FactoryGirl.create :user

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @user.feeds << @feed1

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder
    @user.folders << @folder1

    login_user_for_unit @user

    # Ensure no actual HTTP calls are done
    FeedClient.stub :fetch
    RestClient.stub :get
  end

  context 'GET index' do

    it 'returns success' do
      get :index
      response.should be_success
    end

    it 'assigns to @feeds only feeds the user is suscribed to' do
      get :index
      assigns(:feeds).should eq [@feed1]
    end

    it 'assigns to @folders only folders that belong to the user' do
      get :index
      assigns(:folders).should eq [@folder1]
    end
  end

  context 'GET show' do

    before :each do
      @entry_1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry_1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry_1_1 << @entry_1_2
    end

    it 'assigns to @entries the entries for a single feed' do
      get :show, id: @feed1.id
      assigns(:entries).count.should eq 2
      assigns(:entries).should include @entry_1_1
      assigns(:entries).should include @entry_1_2
    end

    it 'returns a 404 for a feed the user is not suscribed to' do
      get :show, id: @feed2.id
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      get :show, id: 1234567890
      response.status.should eq 404
    end

    it 'does not fetch new entries in the feed' do
      FeedClient.should_not_receive(:fetch).with @feed1.id
      get :show, id: @feed1.id
    end

    it 'assigns to @entries only unread entries by default' do
      feed3 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed3.id
      entry2 = FactoryGirl.build :entry, feed_id: feed3.id
      entry3 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry1 << entry2 << entry3
      @user.feeds << feed3

      entry_state3 = EntryState.where(entry_id: entry3.id, user_id: @user.id).first
      entry_state3.read = true
      entry_state3.save!

      get :show, id: feed3.id
      assigns(:entries).count.should eq 2
      assigns(:entries).should include entry1
      assigns(:entries).should include entry2
    end
  end

  context 'GET refresh' do

    it 'assigns to @entries the new entries of a feed' do
      entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: @feed1.id

      # At first the feed has no entries
      get :refresh, id: @feed1.id
      assigns(:entries).count.should eq 0

      FeedClient.stub :fetch do
        @feed1.entries << entry1 << entry2
      end

      # New entries should appear now
      get :refresh, id: @feed1.id
      assigns(:entries).count.should eq 2
      assigns(:entries).should include entry1
      assigns(:entries).should include entry2
    end

    it 'returns a 404 for a feed the user is not suscribed to' do
      get :refresh, id: @feed2.id
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing feed' do
      get :refresh, id: 1234567890
      response.status.should eq 404
    end

    it 'fetches new entries in the feed before returning' do
      FeedClient.should_receive(:fetch).with @feed1.id
      get :refresh, id: @feed1.id
    end
  end

  context 'POST create' do
    it 'returns 304 if the user is already subscribed to the feed' do
      post :create, subscription: {rss: @feed1.fetch_url}
      response.status.should eq 304

      post :create, subscription: {rss: @feed1.url}
      response.status.should eq 304
    end

    it 'assigns to @feed the new subscribed feed' do
      post :create, subscription: {rss: @feed2.fetch_url}
      response.should  be_success
      assigns(:feed).should eq @feed2
    end
  end

  context 'DELETE remove' do

    it 'does not assign @old_folder if the feed was not in a folder' do
      delete :destroy, id: @feed1.id
      assigns(:old_folder).should be_nil
    end

    it 'assigns @old_folder correctly if the feed was in a folder' do
      @folder1.feeds << @feed1
      delete :destroy, id: @feed1.id
      assigns(:old_folder).should eq @folder1
    end

    it 'deletes the folder if the feed was in a folder without any other feeds' do
      @folder1.feeds << @feed1

      delete :destroy, id: @feed1.id
      Folder.exists?(@folder1.id).should be_false
    end

    it 'returns 404 if the feed does not exist' do
      delete :destroy, id: 1234567890
      response.status.should eq 404
    end

    it 'returns 404 if the user is not subscribed to the feed' do
      delete :destroy, id: @feed2.id
      response.status.should eq 404
    end

    it 'returns 500 if there is a problem unsubscribing' do
      User.any_instance.stub(:unsubscribe).and_raise StandardError.new
      delete :destroy, id: @feed1.id
      response.status.should eq 500
    end
  end
end
