# Handle flash messages in view

$(document).ready ->
  $(window).bind 'rails:flash', (e, params) ->
    $('body').pgNotification(
      style: 'simple'
      message: params.message
      position: 'bottom-left'
      type: params.type
      timeout: 50000).show()
    return
  return