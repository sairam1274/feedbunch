require 'rails_helper'

describe UpdateFeedUnreadCountWorker do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry

    @user.subscribe @feed.fetch_url

    # @feed has an incorrect unread entries count in the db (saved: 0, should be: 1)
    FeedSubscription.find_by(feed_id: @feed.id, user_id: @user.id).update unread_entries: 0
  end

  it 'recalculates unread entries count in feed' do
    UpdateFeedUnreadCountWorker.new.perform @feed.id, @user.id

    # Unread count should be corrected
    expect(@user.feed_unread_count(@feed)).to eq 1
  end

  it 'does nothing if the feed does not exist' do
    expect(SubscriptionsManager).not_to receive :recalculate_unread_count

    expect{UpdateFeedUnreadCountWorker.new.perform 1234567890, @user.id}.to raise_error

    # Unread count should be corrected
    expect(@user.feed_unread_count(@feed)).to eq 0
  end

  it 'does nothing if the user does not exist' do
    expect(SubscriptionsManager).not_to receive :recalculate_unread_count

    expect{UpdateFeedUnreadCountWorker.new.perform @feed.id, 1234567890}.to raise_error

    # Unread count should be corrected
    expect(@user.feed_unread_count(@feed)).to eq 0
  end

  it 'does nothing if the user is not subscribed to the feed' do
    feed2 = FactoryGirl.create :feed
    expect(SubscriptionsManager).not_to receive :recalculate_unread_count

    expect{UpdateFeedUnreadCountWorker.new.perform feed2.id, @user.id}.to raise_error

    # Unread count should be corrected
    expect(@user.feed_unread_count(@feed)).to eq 0
  end
end