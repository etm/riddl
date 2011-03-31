<templates>
  <xslt name="Cinemas-Input" xml:lang="EN" platform="iPhone"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
            <xsl:call-template name="form"/>
      </xsl:template>
      <xsl:template name="form">
          <a onClick="send()" class="button">Send</a>
        <ul>
          <li><b>Movie title: </b><input id="title" caption="Movie Title" value="Gnomeo" style="border:none"/></li> 
          <li><b>Date: </b><input id="date" caption="Date" value="2011-03-31" style="border:none"/></li> 
          <li><b>City: </b><input id="city" caption="City" value="Vienna" style="border:none"/></li> 
        </ul>
        <script type="text/javascript">
          function send() {
            var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>';
            $.ajax({
              url: callback,
              type: 'put',
              dataType: 'text',
              data:{'title': $('#title').val(), 'date': $('#date').val(), 'city': $('#city').val()},
              success: function(res){
                jQT.goBack();
              },
              error: function() {alert('Unable to send data to CPEE instance at ' + callback);}
            });
          }
        </script>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Input" xml:lang="DE" platform="iPhone"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
            <xsl:call-template name="form"/>
      </xsl:template>
      <xsl:template name="form">
          <a onClick="send()" class="button">Absenden</a>
        <ul>
          <li><b>Filmtitle: </b><input id="title" caption="Movie Title" style="border:none"/></li> 
          <li><b>Datum: </b><input id="date" caption="Date" value="2011-03-31" style="border:none"/></li> 
          <li><b>Stadt: </b><input id="city" caption="City" value="Vienna" style="border:none"/></li> 
        </ul>
        <script type="text/javascript">
          function send() {
            var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>';
            $.ajax({
              url: callback,
              type: 'put',
              dataType: 'text',
              data:{'title': $('#title').val(), 'date': $('#date').val(), 'city': $('#city').val()},
              success: function(res){
                jQT.goBack();
              },
              error: function() {alert('Unable to send data to CPEE instance at ' + callback);}
            });
          }
        </script>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Input" xml:lang="EN" platform="Browser"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
        <html>
          <head>
            <script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"/>
            <script type="text/javascript">
              function send() {
                var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>'
                $.ajax({
                  url: callback,
                  type: 'put',
                  dataType: 'text',
                  data:{'title': $('#title').val(), 'date': $('#date').val(), 'city': $('#city').val()},
                  success: function(res){
                    window.setTimeout("window.location.replace('<xsl:value-of select="$worklist"/>');", 500);
                  }
                });
              }
            </script>
          </head>
          <body>
            <xsl:call-template name="form"/>
          </body>
        </html>
      </xsl:template>
      <xsl:template name="form">
        <p> Movie title: <input id="title" value="Gnomeo" caption='Movie Title'/></p> 
        <p> Date: <input id="date" value="2011-03-30" caption="Date"/></p> 
        <p> City: <input id="city" value="Vienna" caption="City/Town"/></p> 
        <input type="button" value="Send" onClick="send()"/>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Input" xml:lang="DE" platform="Browser"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
        <html>
          <head>
            <script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"/>
            <script type="text/javascript">
              function send() {
                var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>'
                $.ajax({
                  url: callback,
                  type: 'put',
                  dataType: 'text',
                  data:{'title': $('#title').val(), 'date': $('#date').val(), 'city': $('#city').val()},
                  success: function(res){
                    window.setTimeout("window.location.replace('<xsl:value-of select="$worklist"/>');", 500);
                  }
                });
              }
            </script>
          </head>
          <body>
            <xsl:call-template name="form"/>
          </body>
        </html>
      </xsl:template>
      <xsl:template name="form">
        <p> Filmtitel: <input id="title" value="Julia" caption='Filmtitle'/></p> 
        <p> Datum: <input id="date" value="2011-03-26" caption="Datum"/></p> 
        <p> Stadt: <input id="city" value="Vienna" caption="Stadt"/></p> 
        <input type="button" value="Send" onClick="send()"/>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Output" xml:lang="EN" platform="iPhone"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
            <xsl:call-template name="form"/>
      </xsl:template>
      <xsl:template name="form">
          <a onClick="send()" class="button">Confirm</a>
        <ul>
          <li><center><b>Booking Confirmation</b></center></li>
          <li><b>Movie title: </b><xsl:value-of select="$title"/></li> 
          <li><b>Cinema: </b><span><xsl:value-of select="$cinema"/></span></li> 
          <li><b>Date: </b><xsl:value-of select="$date"/></li> 
          <li><b>Starting Time: </b><xsl:value-of select="$time"/></li> 
          <li><b>Hall: </b><xsl:value-of select="$hall"/></li> 
          <li><b>Reservation No: </b><span><xsl:value-of select="$res_nr"/></span></li> 
        </ul>
        <script type="text/javascript">
          function send() {
            var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>';
            $.ajax({
              url: callback,
              type: 'put',
              dataType: 'text',
              data:{'confirm': 'true' },
              success: function(res){
                jQT.goBack();
              },
              error: function() {alert('Unable to send data to CPEE instance at ' + callback);}
            });
          }
        </script>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Output" xml:lang="DE" platform="iPhone"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
            <xsl:call-template name="form"/>
      </xsl:template>
      <xsl:template name="form">
          <a onClick="send()" class="button">Confirm</a>
        <ul>
          <li><center><b>Buchungsbestaetigung</b></center></li>
          <li><b>Filmtitel: </b><xsl:value-of select="$title"/></li> 
          <li><b>Kino: </b><span><xsl:value-of select="$cinema"/></span></li> 
          <li><b>Datum: </b><xsl:value-of select="$date"/></li> 
          <li><b>Startzeit: </b><xsl:value-of select="$time"/></li> 
          <li><b>Saal: </b><xsl:value-of select="$hall"/></li> 
          <li><b>Reservierungsnummer: </b><span><xsl:value-of select="$res_nr"/></span></li> 
        </ul>
        <script type="text/javascript">
          function send() {
            var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>';
            $.ajax({
              url: callback,
              type: 'put',
              dataType: 'text',
              data:{'confirm': 'true' },
              success: function(res){
                jQT.goBack();
              },
              error: function() {alert('Unable to send data to CPEE instance at ' + callback);}
            });
          }
        </script>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Output" xml:lang="EN" platform="Browser"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
            <xsl:call-template name="form"/>
      </xsl:template>
      <xsl:template name="form">
          <a onClick="send()" class="button">Confirm</a>
        <ul>
          <li><center><b>Booking Confirmation</b></center></li>
          <li><b>Movie title: </b><xsl:value-of select="$title"/></li> 
          <li><b>Cinema: </b><span><xsl:value-of select="$cinema"/></span></li> 
          <li><b>Date: </b><xsl:value-of select="$date"/></li> 
          <li><b>Starting Time: </b><xsl:value-of select="$time"/></li> 
          <li><b>Hall: </b><xsl:value-of select="$hall"/></li> 
          <li><b>Reservation No: </b><span><xsl:value-of select="$res_nr"/></span></li> 
        </ul>
        <script type="text/javascript">
          function send() {
            var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>';
            $.ajax({
              url: callback,
              type: 'put',
              dataType: 'text',
              data:{'confirm': 'true' },
              success: function(res){
                jQT.goBack();
              },
              error: function() {alert('Unable to send data to CPEE instance at ' + callback);}
            });
          }
        </script>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
  <xslt name="Cinemas-Output" xml:lang="DE" platform="Browser"><!-- {{{ -->
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="html"/>

      <xsl:template match="/">
            <xsl:call-template name="form"/>
      </xsl:template>
      <xsl:template name="form">
          <a onClick="send()" class="button">Confirm</a>
        <ul>
          <li><center><b>Buchungsbestaetigung</b></center></li>
          <li><b>Filmtitel: </b><xsl:value-of select="$title"/></li> 
          <li><b>Kino: </b><span><xsl:value-of select="$cinema"/></span></li> 
          <li><b>Datum: </b><xsl:value-of select="$date"/></li> 
          <li><b>Startzeit: </b><xsl:value-of select="$time"/></li> 
          <li><b>Saal: </b><xsl:value-of select="$hall"/></li> 
          <li><b>Reservierungsnummer: </b><span><xsl:value-of select="$res_nr"/></span></li> 
        </ul>
        <script type="text/javascript">
          function send() {
            var callback = '<xsl:value-of select="$instance-uri"/>/callbacks/<xsl:value-of select="$callback-id"/>';
            $.ajax({
              url: callback,
              type: 'put',
              dataType: 'text',
              data:{'confirm': 'true' },
              success: function(res){
                jQT.goBack();
              },
              error: function() {alert('Unable to send data to CPEE instance at ' + callback);}
            });
          }
        </script>
      </xsl:template>
    </xsl:stylesheet>
  </xslt><!-- }}} -->
</templates>
