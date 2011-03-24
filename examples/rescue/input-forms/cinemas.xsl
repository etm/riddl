<templates>
  <xslt name="Cinemas-Input" xml:lang="en">
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
        <p> Movie title: <input id="title"/></p> 
        <p> Date: <input id="date"/></p> 
        <p> City: <input id="city"/></p> 
        <input type="button" value="Send" onClick="send()"/>
      </xsl:template>
    </xsl:stylesheet>
  </xslt>
</templates>
