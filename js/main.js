---
---

$(function() {

  $('.ga').on('click', function() {
    var id = $(this).attr('id');
    //alert(id);
    ga('send', 'event', 'button', 'click', id);
  });

});


