require 'nokogiri'
require 'encoding_manager'

##
# Feed entry model. Each instance of this class represents an entry in an RSS or Atom feed.
#
# Instances of this class are saved in the database when fetching and parsing feeds. It's not intended to be
# instanced by the user.
#
# Each entry belongs to exactly one feed.
#
# Each entry has many entry-states, exactly one for each user subscribed to the feed. Each entry-state indicates
# whether each user has read or not this entry.
#
# When a new entry is saved in the database for the first time, it is marked as unread for all users subscribed to
# its feed (by saving as many entry_state instances as subscribed users into the database, all of them with the attribute
# "read" set to false).
#
# Each entry is uniquely identified by its guid within the scope of a given feed.
# Duplicate guids are not allowed for the same feed.
#
# When entries are deleted by an automated cleanup (because they are too old or the feed had too many entries),
# a new DeletedEntry instance is saved in the database with the same feed_id and guid as the deleted entry.
# An entry with the same guid and feed_id as an already existing DeletedEntry is not valid and won't be
# saved in the database (it would indicate an entry that is at once deleted and not deleted).
#
# Attributes of the model:
# - feed_id
# - title
# - url
# - author
# - content
# - summary
# - published
# - guid
#
# All fields except "published" and "feed_id" are sanitized before validation; this is, before saving/updating each
# instance in the database.

class Entry < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  belongs_to :feed
  validates :feed_id, presence: true

  has_many :entry_states, -> {uniq}, dependent: :destroy

  validates :title, presence: true
  validates :url, presence: true, format: {with: URI::regexp(%w{http https})}
  validates :guid, presence: true, uniqueness: {case_sensitive: false, scope: :feed_id}
  validate :entry_not_deleted

  before_validation :fix_attributes
  after_create :set_unread_state

  ##
  # Return a boolean that indicates whether this entry has been marked as read by the passed user.
  #
  # Receives as argument the user for which the read/unread state will be retrieved.
  #
  # If the user is not actually subscribed to the feed, raises a NotSubscribedError.

  def read_by?(user)
    state = EntryState.find_by entry_id: self.id, user_id: user.id
    if state.blank?
      Rails.logger.warn "Tried to find out if user #{user.id} - #{user.email} has read entry #{self.id} from feed #{self.feed_id} to which he is not subscribed. Raising an error."
      raise NotSubscribedError.new
    end
    return state.read
  end

  private

  ##
  # Validate that the entry has not been deleted (there is a deleted_entries record with the
  # same feed_id and guid)

  def entry_not_deleted
    if DeletedEntry.exists? feed_id: self.feed_id, guid: self.guid
      Rails.logger.warn "Failed attempt to save already deleted entry - guid: #{self.try :guid}, published: #{self.try :published}, feed_id: #{self.feed_id}, feed title: #{self.feed.title}"
      errors.add :guid, 'entry already deleted'
    end
  end

  ##
  # Fix any problems with attribute values before validation:
  # - fix any encoding problems, converting to utf-8 if necessary
  # - sanitize values, removing script tags from entry bodies etc.
  # - give default values to missing mandatory attributes

  def fix_attributes
    fix_encoding
    strip_attributes
    remove_comments
    sanitize_attributes
    content_manipulation
    default_attribute_values
    fix_url
  end

  ##
  # Fix problems with encoding in text attributes.
  # Specifically, convert from ISO-8859-1 to UTF-8 if necessary.

  def fix_encoding
    self.title = EncodingManager.fix_encoding self.title
    self.url = EncodingManager.fix_encoding self.url
    self.author = EncodingManager.fix_encoding self.author
    self.content = EncodingManager.fix_encoding self.content
    self.summary = EncodingManager.fix_encoding self.summary
    self.guid = EncodingManager.fix_encoding self.guid
  end

  ##
  # Trim the title, url, author, content, summary and guid of the entry, removing any
  # heading or trailing blank characters.

  def strip_attributes
    self.title = self.title.try :strip
    self.url = self.url.try :strip
    self.author = self.author.try :strip
    self.content = self.content.try :strip
    self.summary = self.summary.try :strip
    self.guid = self.guid.try :strip
  end

  ##
  # Remove HTML comments from entries summary and content markup.

  def remove_comments
    self.summary = remove_xml_comments self.summary if self.summary.present?
    self.content = remove_xml_comments self.content if self.content.present?
  end

  ##
  # Remove all HTML comments (<!-- ... -->) from entries.
  # Receives as argument a string with an HTML fragment.

  def remove_xml_comments(html_fragment)
    html_doc = Nokogiri::HTML html_fragment
    html_doc.css('//comment()').each do |comment|
      comment.remove
    end
    return html_doc.css('body').children.to_s
  end

  ##
  # Sanitize the title, url, author, content, summary and guid of the entry.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_attributes
    self.title = sanitize self.title
    self.url = sanitize self.url
    self.author = sanitize self.author
    self.content = sanitize self.content
    self.summary = sanitize self.summary
    self.guid = sanitize self.guid
  end

  ##
  # Manipulations in entries summary and content markup before saving the entry.

  def content_manipulation
    self.summary = markup_manipulation self.summary if self.summary.present?
    self.content = markup_manipulation self.content if self.content.present?
  end

  ##
  # Manipulations in the passed html fragment

  def markup_manipulation(html_fragment)
    html_doc = Nokogiri::HTML html_fragment
    html_doc = link_manipulations html_doc
    html_doc = image_manipulations html_doc
    return html_doc.css('body').children.to_s
  end

  ##
  # Add the target="_blank" attribute to any links in the passed HTML fragment.
  # Receives as argument a parsed HTML fragment.
  # The attribute will overwrite any target="" attribute that was present in the links

  def link_manipulations(html_doc)
    html_doc.css('a').each do |link|
      link['target'] = '_blank'
    end
    return html_doc
  end


  ##
  # Remove any height, width and style attributes and set a CSS class to horizontally center
  # any images in the passed fragment.
  # Any class attribute in images will be overwritten.
  #
  # Also prepare images to be lazy-loaded with the jquery-unveil library.
  #
  # Receives as argument a parsed HTML fragment.

  def image_manipulations(html_doc)
    html_doc.css('img').each do |img|
      # replace image styling
      img.remove_attribute 'height'
      img.remove_attribute 'width'
      img.remove_attribute 'style'
      img.remove_attribute 'class'

      # prepare image for lazy loading
      src = img['src']
      img['src'] = '/images/Ajax-loader.gif'
      img['data-src'] = src
    end
    return html_doc
  end

  ##
  # Give default values to the title and guid attributes if they are empty.
  # Their default value is the value of the "url" attribute.
  #
  # If the url attribute is not a valid URL but the guid is, the url attribute takes
  # the value of the guid attribute. This probably breaks Atom/RSS spec, but I'd like to support feeds
  # that do this.
  #
  # If the publish date is not present, assume the current datetime as default value. This means
  # entries will be shown as published in the moment they are fetched unless the feed specifies
  # otherwise. This ensures all entries have a publish date which avoids major headaches when ordering.

  def default_attribute_values
    # GUID defaults to the url attribute
    self.guid = self.url if self.guid.blank?

    # title defaults to the url attribute
    self.title = self.url if self.title.blank?

    # if the url attr is not actually a valid URL but the guid is, url attr takes the value of the guid attr
    if (self.url =~ URI::regexp(%w{http https})).nil? && self.guid =~ URI::regexp(%w{http https})
      self.url = self.guid
      # If the url was blank before but now has taken the value of the guid, default the title to this value
      self.title = self.url if self.title.blank?
    end

    # published defaults to the current datetime
    self.published = Time.zone.now if self.published.blank?
  end

  ##
  # Fix problems with the entry URL, by URL-encoding any illegal characters and converting relative URLs to absolute ones.

  def fix_url
    if self.url.present?
      # URL-encode illegal characters
      self.url = URI.encode self.url.to_str

      # if the entry url is relative, try to make it absolute using the feed's host
      uri = URI self.url
      if uri.relative?
        # Use host from feed URL, or if the feed only has a fetch URL use it instead.
        if self.feed.url.present?
          uri_feed = URI self.feed.url
        else
          uri_feed = URI self.feed.fetch_url
        end
        absolute_uri = URI uri
        absolute_uri.scheme = uri_feed.scheme
        absolute_uri.host = uri_feed.host
        # Path must begin with a '/'
        uri.path = '/' + uri.path if uri.path[0] != '/'
        absolute_uri.path = uri.path
        self.url = absolute_uri.to_s
      end
    end
  end

  ##
  # For each user subscribed to this entry's feed, save an entry_state instance with the "read" attribute set to false.
  #
  # Or in layman's terms: mark this entry as unread for all users subscribed to the feed.

  def set_unread_state
    self.feed.users(true).each do |user|
      if !EntryState.exists? user_id: user.id, entry_id: self.id
        entry_state = user.entry_states.create entry_id: self.id, read: false
      end
    end
  end

end
