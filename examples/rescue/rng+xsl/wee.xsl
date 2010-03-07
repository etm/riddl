<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:flow="http://rescue.org/ns/controlflow/0.2">
 
 <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:text>&#xa;# Define context variables&#xa;</xsl:text>
    <xsl:apply-templates select="//flow:context"/>
    <xsl:text>&#xa;&#xa;# Define enpoint variables&#xa;</xsl:text>
    <xsl:apply-templates select="//flow:endpoint"/>
    <xsl:text>&#xa;&#xa;# Define controlflow&#xa;</xsl:text>
    <xsl:text>&#xa;&#xa;control flow do</xsl:text>
    <xsl:apply-templates select="/flow:controlflow/flow:*[(name() != 'endpoint') and (name() != 'context')]"/>
    <xsl:text>&#xa;end&#xa;</xsl:text>
  </xsl:template>

  <xsl:template name="prefix-whitespaces">
  <!-- {{{ -->
    <xsl:param name="index" select="1"/>
    <xsl:text>  </xsl:text>
    <xsl:if test="(count(ancestor::flow:*)) &gt; $index">
      <xsl:call-template name="prefix-whitespaces">
        <xsl:with-param name="index" select="$index +1"/>
      </xsl:call-template>
    </xsl:if>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:call">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>activity :</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>, :call, :</xsl:text>
    <xsl:value-of select="@endpoint"/>
    <xsl:text>, input = {</xsl:text>
    <xsl:apply-templates select="child::flow:input"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="string(@http-method)">
      <xsl:text>, http = {:method => '</xsl:text>
      <xsl:value-of select="@http-method"/>
      <xsl:text>', :status => </xsl:text>
      <xsl:value-of select="@http-status"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="string(@service-operation)">
      <xsl:text>, service = {:operation => '</xsl:text>
      <xsl:value-of select="@service-operation"/>
      <xsl:text>', :controlflow => </xsl:text>
      <xsl:value-of select="@state-controlflow"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="string(@group-by)">
      <xsl:text>, group = {:group_selector => '</xsl:text>
      <xsl:value-of select="@group-by"/>
      <xsl:text>', :uri_selector => </xsl:text>
      <xsl:value-of select="child::flow:resource-id/@xpath"/>
      <xsl:text>', :target_endpoint => </xsl:text>
      <xsl:value-of select="child::flow:resource-id/@endpoint"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text> do </xsl:text>
    <xsl:for-each select="child::flow:*[name() != 'input']">
      <xsl:if test="position() = 1">
        <xsl:text>|</xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="string(@parameter-name)">
      <xsl:value-of select="@parameter-name"/>
        </xsl:when>
        <xsl:when test="string(@name)">
      <xsl:value-of select="@name"/>
        </xsl:when>
      </xsl:choose>
      <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:if test="position() = last()">
        <xsl:text>|</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:apply-templates select="child::flow:*[name() != 'input']"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:output">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:variable name="context" select="@context"/>
    <xsl:choose>
      <xsl:when test="string(@name) and string(@context)">
        <xsl:choose>
          <xsl:when test="ancestor::flow:cycle/flow:iterated-context[@id = $context]">
            <xsl:variable name="cycle" select="ancestor::flow:cycle[flow:iterated-context[@id = $context]]"/>
            <xsl:text>"@</xsl:text>
            <xsl:value-of select="$cycle/@id"/>
            <xsl:text>_</xsl:text>
            <xsl:value-of select="@context"/>
            <xsl:text>_#{@</xsl:text>
            <xsl:value-of select="$cycle/@id"/>
            <xsl:text>_iterator}".to_sym</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>@</xsl:text>
            <xsl:value-of select="@context"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> = </xsl:text>
        <xsl:value-of select="@name"/>
      </xsl:when>
      <xsl:when test="string(@message-parameter)">
        <xsl:text>@</xsl:text>
        <xsl:value-of select="parent::flow:call/@id"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="@message-parameter"/>
        <xsl:text> = </xsl:text>
        <xsl:choose>
          <xsl:when test="string(@name)">
            <xsl:value-of select="@name"/>
          </xsl:when>
          <xsl:when test="string(@fix-value)">
            <xsl:call-template name="is_string">
              <xsl:with-param name="v" select="@fix-value"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="string(@context)">
            <xsl:text>@</xsl:text>
            <xsl:value-of select="@context"/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:input">
    <!-- {{{ --> 
    <xsl:text>:</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:choose>
      <xsl:when test="string(@context)">
          <xsl:text> => @</xsl:text>
          <xsl:value-of select="@context"/>
      </xsl:when>
      <xsl:when test="string(@message-parameter)">
          <xsl:text>input[:</xsl:text><xsl:value-of select="@message-parameter"/><xsl:text>]</xsl:text>
      </xsl:when>
      <xsl:when test="string(@fix-value)">
          <xsl:text>input[:</xsl:text>
            <xsl:call-template name="is_string">
              <xsl:with-param name="v" select="@fix-value"/>
            </xsl:call-template>
          <xsl:text>]</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="position() != last()">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:manipulate">
    <!-- {{{ --> 
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:choose>
      <xsl:when test="string(@parameter-name)">
        <xsl:text>@</xsl:text>
        <xsl:value-of select="@target"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="@operator"/>
        <xsl:text>= </xsl:text>
        <xsl:value-of select="@parameter-name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>activity :</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>, :manipulate do&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>  @</xsl:text>
        <xsl:value-of select="@target"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="@operator"/>
        <xsl:text>= </xsl:text>
        <xsl:choose>
          <xsl:when test="string(@variable)">
            <xsl:text> @</xsl:text>
            <xsl:value-of select="@variable"/>
          </xsl:when>
          <xsl:when test="string(@fix-value)">
            <xsl:call-template name="is_string">
              <xsl:with-param name="v" select="@fix-value"/>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>end</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <!-- }}} --> 
  </xsl:template>
  
  <xsl:template match="//flow:critical">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>critical(:</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>) do </xsl:text>
    <xsl:apply-templates select="child::flow:*[(name() != 'endpoint') and (name() != 'context')]"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:parallel">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>parallel (:</xsl:text>
    <xsl:value-of select="@type"/>
    <xsl:text>)</xsl:text>
    <xsl:apply-templates select="child::flow:branch"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:branch">
    <!-- {{{ --> 
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>parallel_branch do</xsl:text>
    <xsl:apply-templates select="child::flow:*[(name() != 'endpoint') and (name() != 'context')]"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:cycle">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>context :</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:variable name="cycle_id" select="@id"/>
    <xsl:text>_iterator => 1&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>cycle(</xsl:text>
    <xsl:apply-templates select="child::flow:group"/>
    <xsl:apply-templates select="child::flow:condition"/>
    <xsl:text>) do </xsl:text>
    <xsl:for-each select="child::flow:iterated-context">
      <xsl:text>&#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>context "</xsl:text>
      <xsl:value-of select="$cycle_id"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>_#{@</xsl:text>
      <xsl:value-of select="$cycle_id"/>
      <xsl:text>_iterator}".to_sym => nil</xsl:text>
    </xsl:for-each>
    <xsl:apply-templates select="child::flow:*[(name() != 'group') and (name() != 'condition') and (name() != 'endpoint') and (name() != 'context') and (name() != 'iterated-context')]"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>  @</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>_iterator++</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:choose">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>choose do</xsl:text>
    <xsl:apply-templates select="child::flow:alternative"/>
    <xsl:apply-templates select="child::flow:otherwise"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:alternative">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>alternative(</xsl:text>
    <xsl:apply-templates select="child::flow:group"/>
    <xsl:apply-templates select="child::flow:condition"/>
    <xsl:text>) do </xsl:text>
    <xsl:apply-templates select="child::flow:*[(name() != 'group') and (name() != 'condition') and (name() != 'endpoint') and (name() != 'context')]"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:otherwise">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>otherwise do</xsl:text>
    <xsl:apply-templates select="child::flow:*[(name() != 'endpoint') and (name() != 'context')]"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:group">
    <!-- {{{ -->
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="child::flow:*"/>
    <xsl:text>)</xsl:text>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:condition">
    <!-- {{{ -->
    <xsl:text>(@</xsl:text>
    <xsl:value-of select="@test"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="@operator"/>
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when test="string(@fix-value)">
        <xsl:call-template name="is_string">
          <xsl:with-param name="v" select="@fix-value"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="string(@variable)">
        <xsl:text>@</xsl:text><xsl:value-of select="@variable"/>
      </xsl:when>
    </xsl:choose>
    <xsl:text>)</xsl:text>
    <xsl:if test="(name(parent::flow:*) = 'group') and (position() != last())">
      <xsl:text> </xsl:text>
      <xsl:value-of select="parent::flow:group/@operator"/>
      <xsl:text> </xsl:text>
    </xsl:if>
    <!-- }}} --> 
  </xsl:template>

  <xsl:template match="//flow:context">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>context :</xsl:text><xsl:value-of select="@id"/><xsl:text> => </xsl:text>
    <xsl:call-template name="is_string">
      <xsl:with-param name="v" select="text()"/>
    </xsl:call-template>
    <!-- }}} -->
  </xsl:template>

  <!-- Template for endpoints variables -->
  <xsl:template match="//flow:endpoint">
    <!-- {{{ -->
    <xsl:text>&#xa;  </xsl:text>
    <xsl:text>endpoint :</xsl:text><xsl:value-of select="@id"/><xsl:text> => '</xsl:text><xsl:value-of select="."/>
    <!-- }}} -->
  </xsl:template>

  <xsl:template name="is_string">
    <!-- {{{ -->
    <xsl:param name="v"/>
    <xsl:choose>
      <xsl:when test= "(string(number($v)) = 'NaN') and ($v != 'nil')">
        <xsl:text>'</xsl:text><xsl:value-of select="$v"/><xsl:text>'</xsl:text>
      </xsl:when>
      <xsl:when test="not(string($v))">
        <xsl:text>nil</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$v"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- }}} -->
  </xsl:template>
</xsl:stylesheet>
