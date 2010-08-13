function onFlashAppCreationComplete() {
  $('#record_button').removeClass('hidden');
}

$(document).ready(function(){
  $("#record_button").toggle(
    function() {
      $(this).toggleClass('record stop');
      // start recording
      document['xrecord_widget'].start_recording();
    },
    function() {
      $(this).toggleClass('record stop');
      document['xrecord_widget'].stop_recording();
      // signal post processing here
   }); 
});

