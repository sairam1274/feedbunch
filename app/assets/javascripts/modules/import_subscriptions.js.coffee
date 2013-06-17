#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Show "Import subscriptions" popup when clicking on the import link
  #-------------------------------------------------------
  $("body").on "click", "a[data-import-subscriptions]", ->
    show_popup()

  #-------------------------------------------------------
  # Submit the "import subscriptions" form when clicking on the "Upload" button
  #-------------------------------------------------------
  $("body").on "click", "#import-subscriptions-submit", ->
    $("#form-import-subscriptions").submit()

  #-------------------------------------------------------
  # Close the popup when submitting the form
  #-------------------------------------------------------
  $("body").on "submit", "#form-import-subscriptions", ->

    # If the user has not selected a file to upload, close the popup and to not POST
    # Form submit will be a full browser POST, because POSTing files via Ajax is not
    # widely supported in older browsers.
    if $("#import_subscriptions_file").val() == ''
      close_popup()
      return false

  #-------------------------------------------------------
  # Periodically update the import process status while it is running
  #-------------------------------------------------------
  update_status_timer = ->

    update_import_status = ->
      # Update the page with the received status
      status_received = (data, textStatus, xhr) ->
        status = data["status"]
        if status == "NONE"
          update_status_html data["status_html"]
          clearInterval timer_update
        else if status == "SUCCESS"
          update_status_html data["status_html"]
          clearInterval timer_update
          Openreader.alertTimedShowHide $("#import-process-success")
        else if status == "ERROR"
          update_status_html data["status_html"]
          clearInterval timer_update
          Openreader.alertTimedShowHide $("#import-process-error")
        else if status == "RUNNING"
          update_status_html data["status_html"]

      # Load the status via Ajax
      $.get("/subscriptions_data", null, status_received, 'json')
        .fail (xhr, textStatus, errorThrown) ->
          if xhr.status != 304
            Openreader.alertTimedShowHide $("#problem-updating-import-status")

    timer_update = setInterval update_import_status, 5000

  #-------------------------------------------------------
  # If the "import running" div is shown, periodically update import status
  #-------------------------------------------------------

  if $("#import-subscriptions-running").length
    update_status_timer()

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#import-subscriptions-popup").modal "show"

  #-------------------------------------------------------
  # Clean file field and close modal popup
  #-------------------------------------------------------
  close_popup = ->
    $("#import_subscriptions_file").val('')
    $("#import-subscriptions-popup").modal 'hide'

  #-------------------------------------------------------
  # Load the import status div sent by the server, replacing the current one
  #-------------------------------------------------------
  update_status_html = (status_html)->
    $("#import-process-status").html status_html