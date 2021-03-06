##
# Class with methods related to managing invitations sent to potential users.

class InvitationsManager

  ##
  # Destroy old User records corresponding to invitations sent but never accepted.
  # This will trigger the destruction of associated records (opml_import_job_state, etc).
  # The interval after which an unaccepted invitation is discarded is configured with
  # the config.discard_unaccepted_invitations_after option in config/application.rb

  def self.destroy_old_invitations
    invitations_older_than = Time.zone.now - Feedbunch::Application.config.discard_unaccepted_invitations_after
    Rails.logger.info "Destroying unaccepted invitations sent before #{invitations_older_than}"

    old_unaccepted_invitations = User.
      where 'invitation_token is not null AND invitation_accepted_at is null AND invitation_sent_at < ?',
            invitations_older_than

    if old_unaccepted_invitations.empty?
      Rails.logger.info 'No old unaccepted invitations need to be destroyed'
      return
    end
    Rails.logger.info "Destroying #{old_unaccepted_invitations.count} old unaccepted invitations"

    old_unaccepted_invitations.destroy_all
  end

  ##
  # Set the daily invitations limit for all users to the value configured in application.rb, in the
  # daily_invitations_limit config option.

  def self.update_daily_limit
    limit = Feedbunch::Application.config.daily_invitations_limit
    Rails.logger.info "Setting the daily invitations limit for all users to #{limit}"
    users = User.where 'invitation_limit != ? or invitation_limit is null', limit
    Rails.logger.debug "A total of #{users.length} users have an invitation limit that needs updating"
    users.each {|u| u.update invitation_limit: limit}
  end

  ##
  # Reset to zero the invitations_count attribute for users that:
  # - have a current invitations count greater than zero
  # - more than one day has passed since their count was reset, as indicated by the
  # invitations_count_reset_at attribute
  #
  # Users who have their invitations_count set to zero, also have their invitations_count_reset_at
  # attribute set to the current date-time. This makes it possible to select only users that had their
  # last invitations_count reset more than one day ago.
  #
  # This method is intended to be invoked daily from a scheduled job. It basically resets to zero the
  # invitations count for each user daily.

  def self.reset_invitations_count
    last_reset_at = Time.zone.now - 1.day
    Rails.logger.info "Resetting users daily invitations count to zero. Ignoring users who had it reset later than #{last_reset_at}"
    users = User.where 'invitations_count > 0 and (invitations_count_reset_at <= ? or invitations_count_reset_at is null)', last_reset_at
    Rails.logger.debug "Resetting invitations count for #{users.length} users"
    users.each {|u| u.update invitations_count: 0, invitations_count_reset_at: Time.zone.now}
  end
end