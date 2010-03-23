<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:flow="http://rescue.org/ns/controlflow/0.2">

  <xsl:include href="xml-to-string.xsl"/>
  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:apply-templates select="/flow:controlflow/flow:*"/>
    <xsl:text>&#xa;</xsl:text>
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

  <xsl:template name="resolve-variable">
    <!-- {{{{ -->
    <xsl:param name="var" select="@variable"/>
    <xsl:choose>
      <xsl:when test="(//flow:context[@id=$var])">
        <xsl:text>context[:"</xsl:text>
        <xsl:value-of select="$var"/>
        <xsl:text>"]</xsl:text>
      </xsl:when>
      <xsl:when test="//flow:endpoint[@id=$var]">
        <xsl:text>endpoints[:"</xsl:text>
        <xsl:value-of select="$var"/>
        <xsl:text>"]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text># ERROR: Variable not found - ID: </xsl:text><xsl:value-of select="$var"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- }}}} -->
  </xsl:template>
  
  <xsl:template name="resolve-message-parameter">
    <!-- {{{ -->
    <xsl:text>context[:"</xsl:text>
    <xsl:value-of select="parent::flow:call/@id"/>
    <xsl:text>_</xsl:text>
    <xsl:value-of select="@message-parameter"/>
    <xsl:text>"]</xsl:text>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:copy">
    <!-- {{{ -->
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>&lt;xsl:variable name=&quot;</xsl:text>
    <xsl:value-of select="@xsl-name"/>
    <xsl:text>&quot; select=&quot;#{</xsl:text>
    <xsl:call-template name="resolve-variable">
      <xsl:with-param name="var" select="@variable"/>
    </xsl:call-template>
    <xsl:text>}&quot;&gt;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <!-- }}} -->
  </xsl:template>

  <xsl:template name="input">
    <!-- {{{ -->
    <xsl:param name="input" select="child::flow:input"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>input = Hash.new</xsl:text>
    <xsl:for-each select="$input">
      <xsl:variable name="id" select="generate-id()"/>
      <xsl:choose>
        <xsl:when test="string(@transformation-uri)">
          <xsl:text>&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>parallel_branch do&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>var_</xsl:text>
          <xsl:value-of select="$id"/>
          <xsl:text> = nil&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>activity :transform_input_</xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:text>_</xsl:text>
          <xsl:value-of select="parent::flow:call/@id"/>
          <xsl:text>_</xsl:text>
          <xsl:value-of select="$id"/>
          <xsl:text>, :</xsl:text>
          <xsl:value-of select="@transformation-uri"/>
          <xsl:text>, inputs = {:xml => </xsl:text>
          <xsl:choose>
            <xsl:when test="string(@variable)">
              <xsl:call-template name="resolve-variable">
                <xsl:with-param name="var" select="@variable"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="string(@message-parameter)">
              <xsl:call-template name="resolve-message-parameter"/>
            </xsl:when>
          </xsl:choose>
          <xsl:text>, :xsl => &#xa;&lt;&lt;XSLT&#xa;</xsl:text>
            <xsl:apply-templates select="child::flow:copy"/>
            <xsl:call-template name="prefix-whitespaces"/>
            <xsl:call-template name="xml-to-string">
              <xsl:with-param name="node-set" select="child::xsl:*"/>
            </xsl:call-template>
            <xsl:text>&#xa;XSLT&#xa;</xsl:text>
            <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>}</xsl:text>
          <xsl:text> do |result|&#xa;</xsl:text>
            <xsl:call-template name="prefix-whitespaces"/>
            <xsl:text>  var_</xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text> = result.values[0]&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>end&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>input[:</xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:text>] = </xsl:text>
          <xsl:text>var_</xsl:text>
          <xsl:value-of select="$id"/>
          <xsl:text>&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>end&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>input[:</xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:text>] = </xsl:text>
          <xsl:choose>
            <xsl:when test="string(@variable)">
              <xsl:call-template name="resolve-variable">
                <xsl:with-param name="var" select="@variable"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="string(@message-parameter)">
              <xsl:call-template name="resolve-message-parameter"/>
            </xsl:when>
            <xsl:when test="string(@fix-value)">
              <xsl:value-of select="@fix-value"/>
            </xsl:when>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <!-- }}} --> 
  </xsl:template>

  <xsl:template match="//flow:constraint">
    <!-- {{{ --> 
    <xsl:text>:</xsl:text>
    <xsl:value-of select="generate-id()"/>
    <xsl:text> => {:xpath => "</xsl:text>
    <xsl:value-of select="@xpath"/>
    <xsl:text>", :comparator => '</xsl:text>
    <xsl:value-of select="@comparator"/>
    <xsl:text>', :value => </xsl:text>
    <xsl:variable name="id" select="@variable"/>
    <xsl:choose>
      <xsl:when test="string(@variable)">
        <xsl:call-template name="resolve-variable">
          <xsl:with-param name="var" select="@variable"/>
          <xsl:with-param name="operation" select="'get'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="string(@fix-value)">
        <xsl:value-of select="@fix-value"/>
      </xsl:when>
      <xsl:when test="string(@message-parameter)">
          <xsl:text>input[:</xsl:text><xsl:value-of select="@message-parameter"/><xsl:text>]</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:if test="position() != last()">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:call">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>parallel (:wait) do</xsl:text>
    <xsl:call-template name="input"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>activity :</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>, :call, :</xsl:text>
    <xsl:value-of select="@endpoint"/>
    <xsl:text>, input</xsl:text>
    <xsl:if test="string(@http-method)">
      <xsl:text>, &#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>    http-method = '</xsl:text>
      <xsl:value-of select="@http-method"/>
      <xsl:text>'</xsl:text>
    </xsl:if>
    <xsl:if test="string(@service-operation)">
      <xsl:text>, &#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>    service = {:operation => '</xsl:text>
      <xsl:value-of select="@service-operation"/>
      <xsl:text>', :controlflow => '</xsl:text>
      <xsl:value-of select="@state-controlflow"/>
      <xsl:text>'}</xsl:text>
    </xsl:if>
    <xsl:if test="string(@group-by)">
      <xsl:text>, &#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>    group = {:group_selector => '</xsl:text>
      <xsl:value-of select="@group-by"/>
      <xsl:text>', :uri_selector => </xsl:text>
      <xsl:value-of select="child::flow:resource-id/@xpath"/>
      <xsl:text>', :target_endpoint => </xsl:text>
      <xsl:value-of select="child::flow:resource-id/@endpoint"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="child::flow:constraint">
      <xsl:text>, &#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>    constraint = {</xsl:text>
      <xsl:apply-templates select="child::flow:constraint"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>do |result|</xsl:text>
    <xsl:apply-templates select="child::flow:output">
      <xsl:with-param name="mode" select="'assign'"/>
    </xsl:apply-templates>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>parallel (:wait) do</xsl:text>
    <xsl:apply-templates select="child::flow:output">
      <xsl:with-param name="mode" select="'transform'"/>
    </xsl:apply-templates>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:output">
    <!-- {{{ -->
    <xsl:param name="mode"/>
    <xsl:choose>
      <xsl:when test="$mode = 'assign'">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:choose>
          <xsl:when test="string(@message-parameter)">
          <!-- Message-Parameter is the target -->
            <xsl:call-template name="resolve-message-parameter"/>
            <xsl:text> = </xsl:text>
            <xsl:choose>
              <xsl:when test="string(@variable)">
                <xsl:call-template name="resolve-variable">
                  <xsl:with-param name="var" select="@variable"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="string(@name)">
                <xsl:text>result[:</xsl:text>
                <xsl:value-of select="@name"/>
                <xsl:text>]</xsl:text>
              </xsl:when>
              <xsl:when test="string(@fix-value)">
                <xsl:value-of select="@fix-value"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="not(string(@message-parameter))and (string(@variable))">
          <!-- Context is the target -->
            <xsl:call-template name="resolve-variable">
              <xsl:with-param name="var" select="@variable"/>
            </xsl:call-template>
            <xsl:text> = </xsl:text>
            <xsl:choose>
              <xsl:when test="string(@name)">
                <xsl:text>result[:</xsl:text>
                <xsl:value-of select="@name"/>
                <xsl:text>]</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>") # ERROR during assignment of output</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="($mode = 'transform') and (child::xsl:*)">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>parallel_branch do&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>activity :transform_output_</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="parent::flow:call/@id"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="generate-id()"/>
        <xsl:text>, :</xsl:text>
        <xsl:value-of select="@transformation-uri"/>
        <xsl:text>, inputs = {:xml => </xsl:text>
        <xsl:choose>
          <xsl:when test="string(@variable)">
            <xsl:call-template name="resolve-variable">
              <xsl:with-param name="var" select="@variable"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="string(@message-parameter)">
            <xsl:call-template name="resolve-message-parameter"/>
          </xsl:when>
        </xsl:choose>
        <xsl:text>, :xsl => &#xa;&lt;&lt;XSLT&#xa;</xsl:text>
          <xsl:apply-templates select="child::flow:copy"/>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:call-template name="xml-to-string">
            <xsl:with-param name="node-set" select="child::xsl:*"/>
          </xsl:call-template>
          <xsl:text>&#xa;XSLT&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>}</xsl:text>
        <xsl:text> do |result|&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>  </xsl:text>
          <xsl:choose>
            <xsl:when test="string(@variable)">
              <xsl:call-template name="resolve-variable">
                <xsl:with-param name="var" select="@variable"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="string(@message-parameter)">
              <xsl:call-template name="resolve-message-parameter"/>
            </xsl:when>
          </xsl:choose>
          <xsl:text> = result.values[0]&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>end&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>end&#xa;</xsl:text>
      </xsl:when>
    </xsl:choose>
    <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:instruction">
    <!-- {{{ -->
    <xsl:param name="mode"/>
    <xsl:variable name="var" select="@variable"/>
    <xsl:variable name="target" select="@target"/>
    <xsl:choose>
      <xsl:when test="($mode = 'transform') and (child::xsl:*)">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:value-of select="generate-id()"/>
        <xsl:text> = </xsl:text>
        <xsl:choose>
          <xsl:when test="preceding-sibling::flow:instruction[@target = $target]">
            <xsl:value-of select="generate-id(preceding-sibling::flow:instruction[@target = $target][1])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="resolve-variable">
              <xsl:with-param name="var" select="@target"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>activity :transform_instruction_</xsl:text>
        <xsl:value-of select="@target"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="parent::flow:manipulate/@id"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="generate-id()"/>
        <xsl:text>, :</xsl:text>
        <xsl:value-of select="@transformation-uri"/>
        <xsl:text>, inputs = {:xml => </xsl:text>
        <xsl:choose>
          <xsl:when test="preceding-sibling::flow:instruction[@target = $var]">
            <xsl:value-of select="generate-id(preceding-sibling::flow:instruction[@target = $var][1])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="resolve-variable">
              <xsl:with-param name="var" select="@variable"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>, :xsl => &#xa;&lt;&lt;XSLT&#xa;</xsl:text>
          <xsl:apply-templates select="child::flow:copy"/>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:call-template name="xml-to-string">
            <xsl:with-param name="node-set" select="child::xsl:*"/>
          </xsl:call-template>
          <xsl:text>&#xa;XSLT&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>}</xsl:text>
        <xsl:text> do |result|&#xa;</xsl:text>
          <xsl:call-template name="prefix-whitespaces"/>
          <xsl:text>  </xsl:text>
          <xsl:value-of select="generate-id()"/>
          <xsl:if test="not(contains(@operator, '='))">
            <xsl:text>.</xsl:text>
          </xsl:if>
          <xsl:value-of select="@operator"/>
          <xsl:if test="not(contains(@operator, '='))">
            <xsl:text>(</xsl:text>
          </xsl:if>
          <xsl:text>result.values[0]</xsl:text>
          <xsl:if test="not(contains(@operator, '='))">
            <xsl:text>)</xsl:text>
          </xsl:if>
          <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:text>end&#xa;</xsl:text>
      </xsl:when>
      <xsl:when test="($mode = 'transform')">
        <xsl:value-of select="generate-id()"/>
        <xsl:text> = </xsl:text>
        <xsl:choose>
          <xsl:when test="preceding-sibling::flow:instruction[@target = $target]">
            <xsl:value-of select="generate-id(preceding-sibling::flow:instruction[@target = $target][1])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="resolve-variable">
              <xsl:with-param name="var" select="@target"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:value-of select="generate-id()"/>
        <xsl:if test="not(contains(@operator, '='))">
          <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:value-of select="@operator"/>
        <xsl:if test="not(contains(@operator, '='))">
          <xsl:text>(</xsl:text>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="preceding-sibling::flow:instruction[@target = $var]">
            <xsl:value-of select="generate-id(preceding-sibling::flow:instruction[@target = $var])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="string(@variable)">
                <xsl:call-template name="resolve-variable">
                  <xsl:with-param name="var" select="@variable"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@fix-value"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="not(contains(@operator, '='))">
          <xsl:text>)</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="prefix-whitespaces"/>
        <xsl:call-template name="resolve-variable">
          <xsl:with-param name="var" select="@target"/>
        </xsl:call-template>
        <xsl:text> = </xsl:text>
        <xsl:value-of select="generate-id()"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- }}} -->  
  </xsl:template>

  <xsl:template match="//flow:manipulate">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:apply-templates name="child::flow:instruction">
      <xsl:with-param name="mode" select="'transform'"/>
    </xsl:apply-templates>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>activity :</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>, :manipulate do</xsl:text>
    <xsl:apply-templates select="flow:context"/>
    <xsl:apply-templates select="flow:endpoint"/>
    <xsl:apply-templates select="flow:instruction"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
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
    <xsl:text>) do</xsl:text>
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
    <xsl:text>cycle(</xsl:text>
    <xsl:apply-templates select="child::flow:group"/>
    <xsl:apply-templates select="child::flow:condition"/>
    <xsl:text>) do </xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="child::flow:*[(name() != 'group') and (name() != 'condition')]"/>
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
    <xsl:apply-templates select="child::flow:*[(name() != 'group') and (name() != 'condition')]"/>
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
    <xsl:text>(</xsl:text>
    <xsl:call-template name="resolve-variable">
      <xsl:with-param name="var" select="@test"/>
    </xsl:call-template>
    <xsl:text>.</xsl:text>
    <xsl:value-of select="@comparator"/>
    <xsl:text>(</xsl:text>
    <xsl:choose>
      <xsl:when test="string(@fix-value)">
        <xsl:value-of select="@fix-value"/>
      </xsl:when>
      <xsl:when test="string(@variable)">
        <xsl:call-template name="resolve-variable">
          <xsl:with-param name="var" select="@variable"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
    <xsl:text>)</xsl:text>
    <xsl:text>)</xsl:text>
    <xsl:if test="(name(parent::flow:*) = 'group') and (position() != last())">
      <xsl:text> </xsl:text>
      <xsl:value-of select="parent::flow:group/@connector"/>
      <xsl:text> </xsl:text>
    </xsl:if>
    <!-- }}} --> 
  </xsl:template>

  <xsl:template match="//flow:context">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>context :"</xsl:text><xsl:value-of select="@id"/><xsl:text>" => </xsl:text>
    <xsl:if test="not(string(text()))">
      <xsl:text> nil</xsl:text>
    </xsl:if>
    <xsl:value-of select="text()"/>
    <!-- }}} --> 
  </xsl:template>

  <xsl:template match="//flow:endpoint">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>endpoint :"</xsl:text><xsl:value-of select="@id"/><xsl:text>" => </xsl:text>
    <xsl:if test="not(string(text()))">
      <xsl:text> nil</xsl:text>
    </xsl:if>
    <xsl:value-of select="text()"/>
    <!-- }}} -->
  </xsl:template>
</xsl:stylesheet>
