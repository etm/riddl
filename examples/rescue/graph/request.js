function make_request(url, success) {
  http_request = false;
  if (window.XMLHttpRequest) { // Mozilla, Safari,...
    http_request = new XMLHttpRequest();
    if (http_request.overrideMimeType) {
      http_request.overrideMimeType('text/xml');
    }
  } else if (window.ActiveXObject) { // IE
    try {
      http_request = new ActiveXObject("Msxml2.XMLHTTP");
    } catch (e) {
      try {
        http_request = new ActiveXObject("Microsoft.XMLHTTP");
      } catch (e) {}
    }
  }

  if (!http_request) {
    alert('Error creating HTTP-request object :(');
    return false;
  }

  http_request.onreadystatechange = ready_state;
  http_request.open('GET', url, true);
  http_request.send(null);
}

function ready_state() {
  if (http_request.readyState == 4) {
    if (http_request.status == 200) {
      success(http_request.responseText);
    } else {
      alert('Error precessing request');
    }
  }
}

