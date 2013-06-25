<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" doctype-public="XSLT-compat"/>
  <xsl:template match="*">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
      <head>
         <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
         <title>Further Explore the Notifications</title>
         <script src="http://code.jquery.com/jquery-1.9.1.js"></script>
         <script src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>
         <script type="text/javascript">
            $(document).ready(function(){
                troublesome(); 
             });
            function troublesome(){
              var chi =$("#lagiacrus").children();
              chi.each(function(){ replacing($(this)); });
            }
            function replacing(han){
                var parent = han;
                var taggl = parent.children('#jacen');
                if (taggl.children().length>0){ 
                  taggl.children().each(function(){ replacing($(this));});
                }
                var temp = taggl.html().split("gt");
                var replacement = "&lt;solo id=jacen&gt;"+temp[0]+"gt;&lt;/solo&gt;";
                var real_one ="&lt;solo id=jacen&gt;"+taggl.html()+"&lt;/solo&gt;";
                var visibility = 1;
                parent.children('#jaina').click(function(){
                 if(visibility!=0){
                    taggl.replaceWith(replacement);
                    visibility=0;
                    taggl = parent.children('#jacen'); 
                 }else{
                    taggl.replaceWith(real_one);
                    visibility=1;
                    taggl = parent.children('#jacen');
                    if(taggl.children().length>0){
                      taggl.children().each(function(){ replacing($(this));});
                    }                     
                 }
                 });
              }
          </script>
      </head>
      <body>
        <div id="brot">
          <nav>                                                                   
            <xsl:element name="a">
              <xsl:attribute name="href">../../</xsl:attribute>
              Main
            </xsl:element>
            &gt;
            <xsl:element name="a">
              <xsl:attribute name="href">../</xsl:attribute>
              Instanz
            </xsl:element>
            &gt;
            <xsl:element name="a">
              <xsl:attribute name="href">.</xsl:attribute>
              Properties
            </xsl:element>                                                        
          </nav>
        </div>

        <h1>Navigation </h1>
        <ul>
          <li><a href='schema'>Schema</a></li>  
          <li><a href='values'>Values</a></li>  
        </ul>
        <h1>RAW</h1>
        <pre id="lagiacrus">
          <xsl:apply-templates select="node()" mode="XmlEscape"/>
        </pre>
      </body>
    </html>
  </xsl:template>

  <xsl:param name="NL"        select="'&#xA;'" /><!-- newline sequence -->
  <xsl:param name="INDENTSEQ" select="'&#160;&#160;'" /><!-- indent sequence -->

  <xsl:variable name="LT" select="'&lt;'" />
  <xsl:variable name="GT" select="'&gt;'" />

  <xsl:template match="transform-me">
    <html>
      <body>
        <!-- this XML-escapes an entire sub-structure -->
        <pre><xsl:apply-templates select="*" mode="XmlEscape" /></pre>
      </body>
    </html>
  </xsl:template>

  <!-- element nodes will be handled here, incl. proper indenting -->
  <xsl:template match="*" mode="XmlEscape">
    <xsl:param name="indent" select="''" />
    <xsl:choose>
      <xsl:when test="count(./*) &gt; 0">
      <xsl:element name="div">
        <xsl:element name ="a"><xsl:attribute name="href">#</xsl:attribute><xsl:attribute name="id">jaina</xsl:attribute>Run Nudel</xsl:element> 
      <xsl:element name="solo"><xsl:attribute name="id">jacen</xsl:attribute>
    <xsl:value-of select="concat($indent, $LT, name())" />
    <xsl:apply-templates select="@*" mode="XmlEscape" />
    <xsl:variable name="HasChildNode" select="node()[not(self::text())]" />
    <xsl:variable name="HasChildText" select="text()[normalize-space()]" />
    <xsl:choose>
      <xsl:when test="$HasChildNode or $HasChildText">
        <xsl:value-of select="$GT" />
        <xsl:if test="not($HasChildText)">
          <xsl:value-of select="$NL" />
        </xsl:if>
        <!-- render child nodes -->
        <xsl:apply-templates mode="XmlEscape" select="node()">
          <xsl:with-param name="indent" select="concat($INDENTSEQ, $indent)" />
        </xsl:apply-templates>
        <xsl:if test="not($HasChildText)">
          <xsl:value-of select="$indent" />
        </xsl:if>
        <xsl:value-of select="concat($LT, '/', name(), $GT, $NL)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(' /', $GT, $NL)" />
      </xsl:otherwise>
    </xsl:choose>
    </xsl:element>
    </xsl:element>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="concat($indent, $LT, name())" />
    <xsl:apply-templates select="@*" mode="XmlEscape" />
    <xsl:variable name="HasChildNode" select="node()[not(self::text())]" />
    <xsl:variable name="HasChildText" select="text()[normalize-space()]" />
    <xsl:choose>
      <xsl:when test="$HasChildNode or $HasChildText">
        <xsl:value-of select="$GT" />
        <xsl:if test="not($HasChildText)">
          <xsl:value-of select="$NL" />
        </xsl:if>
        <!-- render child nodes -->
        <xsl:apply-templates mode="XmlEscape" select="node()">
          <xsl:with-param name="indent" select="concat($INDENTSEQ, $indent)" />
        </xsl:apply-templates>
        <xsl:if test="not($HasChildText)">
          <xsl:value-of select="$indent" />
        </xsl:if>
        <xsl:value-of select="concat($LT, '/', name(), $GT, $NL)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(' /', $GT, $NL)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:otherwise>
  </xsl:choose>

  </xsl:template>

  <!-- comments will be handled here -->
  <xsl:template match="comment()" mode="XmlEscape">
    <xsl:param name="indent" select="''" />
    <xsl:value-of select="concat($indent, $LT, '!--', ., '--', $GT, $NL)" />
  </xsl:template>

  <!-- text nodes will be printed XML-escaped -->
  <xsl:template match="text()" mode="XmlEscape">
    <xsl:if test="not(normalize-space() = '')">
      <xsl:call-template name="XmlEscapeString">
        <xsl:with-param name="s" select="." />
        <xsl:with-param name="IsAttribute" select="false()" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- attributes become a string: '{name()}="{escaped-value()}"' -->
  <xsl:template match="@*" mode="XmlEscape">
    <xsl:value-of select="concat(' ', name(), '=&quot;')" />
    <xsl:call-template name="XmlEscapeString">
      <xsl:with-param name="s" select="." />
      <xsl:with-param name="IsAttribute" select="true()" />
    </xsl:call-template>
    <xsl:value-of select="'&quot;'" />
  </xsl:template>

  <!-- template to XML-escape a string -->
  <xsl:template name="XmlEscapeString">
    <xsl:param name="s" select="''" />
    <xsl:param name="IsAttribute" select="false()" />
    <!-- chars &, < and > are never allowed -->
    <xsl:variable name="step1">
      <xsl:call-template name="StringReplace">
        <xsl:with-param name="s"       select="$s" />
        <xsl:with-param name="search"  select="'&amp;'" />
        <xsl:with-param name="replace" select="'&amp;amp;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step2">
      <xsl:call-template name="StringReplace">
        <xsl:with-param name="s"       select="$step1" />
        <xsl:with-param name="search"  select="'&lt;'" />
        <xsl:with-param name="replace" select="'&amp;lt;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step3">
      <xsl:call-template name="StringReplace">
        <xsl:with-param name="s"       select="$step2" />
        <xsl:with-param name="search"  select="'&gt;'" />
        <xsl:with-param name="replace" select="'&amp;lt;'" />
      </xsl:call-template>
    </xsl:variable>
    <!-- chars ", TAB, CR and LF are never allowed in attributes -->
    <xsl:choose>
      <xsl:when test="$IsAttribute">
        <xsl:variable name="step4">
          <xsl:call-template name="StringReplace">
            <xsl:with-param name="s"       select="$step3" />
            <xsl:with-param name="search"  select="'&quot;'" />
            <xsl:with-param name="replace" select="'&amp;quot;'" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="step5">
          <xsl:call-template name="StringReplace">
            <xsl:with-param name="s"       select="$step4" />
            <xsl:with-param name="search"  select="'&#x9;'" />
            <xsl:with-param name="replace" select="'&amp;#x9;'" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="step6">
          <xsl:call-template name="StringReplace">
            <xsl:with-param name="s"       select="$step5" />
            <xsl:with-param name="search"  select="'&#xA;'" />
            <xsl:with-param name="replace" select="'&amp;#xD;'" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="step7">
          <xsl:call-template name="StringReplace">
            <xsl:with-param name="s"       select="$step6" />
            <xsl:with-param name="search"  select="'&#xD;'" />
            <xsl:with-param name="replace" select="'&amp;#xD;'" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$step7" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$step3" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- generic string replace template -->
  <xsl:template name="StringReplace">
    <xsl:param name="s"       select="''" />
    <xsl:param name="search"  select="''" />
    <xsl:param name="replace" select="''" />

    <xsl:choose>
      <xsl:when test="contains($s, $search)">
        <xsl:value-of select="substring-before($s, $search)" />
        <xsl:value-of select="$replace" />
        <xsl:variable name="rest" select="substring-after($s, $search)" />
        <xsl:if test="$rest">
          <xsl:call-template name="StringReplace">
            <xsl:with-param name="s"       select="$rest" />
            <xsl:with-param name="search"  select="$search" />
            <xsl:with-param name="replace" select="$replace" />
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$s" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

