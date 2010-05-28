<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://cpee.org/ns/description/1.0"
  xmlns:flow="http://rescue.org/ns/controlflow/0.2">

  <xsl:output method="xml"/>
<!-- XML-To-String -->
<!-- {{{ -->
<!--
Copyright (c) 2001-2009, Evan Lenz
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Lenz Consulting Group nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Recent changes:

2009-10-08: Added $att-value parameter and template name to template rule for attributes.
2009-10-19: Added the $exclude-these-namespaces parameter 
-->

  <xsl:param name="use-empty-syntax" select="true()"/>
  <xsl:param name="exclude-unused-prefixes" select="true()"/>

  <!-- a node-set; each node's string-value
       will be interpreted as a namespace URI to be
       excluded from the serialization. -->
  <xsl:param name="namespaces-to-exclude" select="/.."/>
  <!-- initialized to empty node-set -->

  <xsl:param name="start-tag-start" select="'&lt;'"/>
  <xsl:param name="start-tag-end" select="'&gt;'"/>
  <xsl:param name="empty-tag-end" select="'/&gt;'"/>
  <xsl:param name="end-tag-start" select="'&lt;/'"/>
  <xsl:param name="end-tag-end" select="'&gt;'"/>
  <xsl:param name="space" select="' '"/>
  <xsl:param name="ns-decl" select="'xmlns'"/>
  <xsl:param name="colon" select="':'"/>
  <xsl:param name="equals" select="'='"/>
  <xsl:param name="attribute-delimiter" select="'&quot;'"/>
  <xsl:param name="comment-start" select="'&lt;!--'"/>
  <xsl:param name="comment-end" select="'--&gt;'"/>
  <xsl:param name="pi-start" select="'&lt;?'"/>
  <xsl:param name="pi-end" select="'?&gt;'"/>

  <xsl:template name="xml-to-string">
    <xsl:param name="node-set" select="."/>
    <xsl:apply-templates select="$node-set" mode="xml-to-string">
      <xsl:with-param name="depth" select="1"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="/" name="xml-to-string-root-rule">
    <xsl:call-template name="xml-to-string"/>
  </xsl:template>

  <xsl:template match="/" mode="xml-to-string">
    <xsl:param name="depth"/>
    <xsl:apply-templates mode="xml-to-string">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*" mode="xml-to-string">
    <xsl:param name="depth"/>
    <xsl:variable name="element" select="."/>
    <xsl:value-of select="$start-tag-start"/>
    <xsl:call-template name="element-name">
      <xsl:with-param name="text" select="name()"/>
    </xsl:call-template>
    <xsl:apply-templates select="@*" mode="xml-to-string"/>
    <xsl:for-each select="namespace::*">
      <xsl:call-template name="process-namespace-node">
        <xsl:with-param name="element" select="$element"/>
        <xsl:with-param name="depth" select="$depth"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="node() or not($use-empty-syntax)">
        <xsl:value-of select="$start-tag-end"/>
        <xsl:apply-templates mode="xml-to-string">
          <xsl:with-param name="depth" select="$depth + 1"/>
        </xsl:apply-templates>
        <xsl:value-of select="$end-tag-start"/>
        <xsl:call-template name="element-name">
          <xsl:with-param name="text" select="name()"/>
        </xsl:call-template>
        <xsl:value-of select="$end-tag-end"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$empty-tag-end"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="process-namespace-node">
    <xsl:param name="element"/>
    <xsl:param name="depth"/>
    <xsl:variable name="declaredAbove">
      <xsl:call-template name="isDeclaredAbove">
        <xsl:with-param name="depth" select="$depth - 1"/>
        <xsl:with-param name="element" select="$element/.."/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="is-used-on-this-element" select="($element    | $element/@*) [namespace-uri() = current()]"/>
    <xsl:variable name="is-used-on-a-descendant" select="($element//* | $element//@*)[namespace-uri() = current()]"/>          
    <xsl:variable name="is-unused" select="not($is-used-on-this-element) and                                            not($is-used-on-a-descendant)"/>
    <xsl:variable name="exclude-ns" select="($is-unused and $exclude-unused-prefixes) or                                             (. = $namespaces-to-exclude)"/>

    <xsl:variable name="force-include" select="$is-used-on-this-element and (. = $namespaces-to-exclude)"/>

    <xsl:if test="(name() != 'xml') and ($force-include or (not($exclude-ns) and not(string($declaredAbove))))">
      <xsl:value-of select="$space"/>
      <xsl:value-of select="$ns-decl"/>
      <xsl:if test="name()">
        <xsl:value-of select="$colon"/>
        <xsl:call-template name="ns-prefix">
          <xsl:with-param name="text" select="name()"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:value-of select="$equals"/>
      <xsl:value-of select="$attribute-delimiter"/>
      <xsl:call-template name="ns-uri">
        <xsl:with-param name="text" select="string(.)"/>
      </xsl:call-template>
      <xsl:value-of select="$attribute-delimiter"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="isDeclaredAbove">
    <xsl:param name="element"/>
    <xsl:param name="depth"/>
    <xsl:if test="$depth &gt; 0">
      <xsl:choose>
        <xsl:when test="$element/namespace::*[name(.)=name(current()) and .=current()]">1</xsl:when>
        <xsl:when test="$element/namespace::*[name(.)=name(current())]"/>
        <xsl:otherwise>
          <xsl:call-template name="isDeclaredAbove">
            <xsl:with-param name="depth" select="$depth - 1"/>
            <xsl:with-param name="element" select="$element/.."/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@*" mode="xml-to-string" name="serialize-attribute">
    <xsl:param name="att-value" select="string(.)"/>
    <xsl:value-of select="$space"/>
    <xsl:call-template name="attribute-name">
      <xsl:with-param name="text" select="name()"/>
    </xsl:call-template>
    <xsl:value-of select="$equals"/>
    <xsl:value-of select="$attribute-delimiter"/>
    <xsl:call-template name="attribute-value">
      <xsl:with-param name="text" select="$att-value"/>
    </xsl:call-template>
    <xsl:value-of select="$attribute-delimiter"/>
  </xsl:template>

  <xsl:template match="comment()" mode="xml-to-string">
    <xsl:value-of select="$comment-start"/>
    <xsl:call-template name="comment-text">
      <xsl:with-param name="text" select="string(.)"/>
    </xsl:call-template>
    <xsl:value-of select="$comment-end"/>
  </xsl:template>

  <xsl:template match="processing-instruction()" mode="xml-to-string">
    <xsl:value-of select="$pi-start"/>
    <xsl:call-template name="pi-target">
      <xsl:with-param name="text" select="name()"/>
    </xsl:call-template>
    <xsl:value-of select="$space"/>
    <xsl:call-template name="pi-text">
      <xsl:with-param name="text" select="string(.)"/>
    </xsl:call-template>
    <xsl:value-of select="$pi-end"/>
  </xsl:template>

  <xsl:template match="text()" mode="xml-to-string">
    <xsl:call-template name="text-content">
      <xsl:with-param name="text" select="string(.)"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="element-name">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <xsl:template name="attribute-name">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <xsl:template name="attribute-value">
    <xsl:param name="text"/>
    <xsl:variable name="escaped-markup">
      <xsl:call-template name="escape-markup-characters">
        <xsl:with-param name="text" select="$text"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$attribute-delimiter = &quot;'&quot;">
        <xsl:call-template name="replace-string">
          <xsl:with-param name="text" select="$escaped-markup"/>
          <xsl:with-param name="replace" select="&quot;'&quot;"/>
          <xsl:with-param name="with" select="'&amp;apos;'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$attribute-delimiter = '&quot;'">
        <xsl:call-template name="replace-string">
          <xsl:with-param name="text" select="$escaped-markup"/>
          <xsl:with-param name="replace" select="'&quot;'"/>
          <xsl:with-param name="with" select="'&amp;quot;'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="replace-string">
          <xsl:with-param name="text" select="$escaped-markup"/>
          <xsl:with-param name="replace" select="$attribute-delimiter"/>
          <xsl:with-param name="with" select="''"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ns-prefix">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <xsl:template name="ns-uri">
    <xsl:param name="text"/>
    <xsl:call-template name="attribute-value">
      <xsl:with-param name="text" select="$text"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="text-content">
    <xsl:param name="text"/>
    <xsl:call-template name="escape-markup-characters">
      <xsl:with-param name="text" select="$text"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="pi-target">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <xsl:template name="pi-text">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <xsl:template name="comment-text">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
  </xsl:template>

  <xsl:template name="escape-markup-characters">
    <xsl:param name="text"/>
    <xsl:variable name="ampEscaped">
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="$text"/>
        <xsl:with-param name="replace" select="'&amp;'"/>
        <xsl:with-param name="with" select="'&amp;amp;'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="ltEscaped">
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="$ampEscaped"/>
        <xsl:with-param name="replace" select="'&lt;'"/>
        <xsl:with-param name="with" select="'&amp;lt;'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="replace-string">
      <xsl:with-param name="text" select="$ltEscaped"/>
      <xsl:with-param name="replace" select="']]&gt;'"/>
      <xsl:with-param name="with" select="']]&amp;gt;'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="replace-string">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="with"/>
    <xsl:variable name="stringText" select="string($text)"/>
    <xsl:choose>
      <xsl:when test="contains($stringText,$replace)">
        <xsl:value-of select="substring-before($stringText,$replace)"/>
        <xsl:value-of select="$with"/>
        <xsl:call-template name="replace-string">
          <xsl:with-param name="text" select="substring-after($stringText,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="with" select="$with"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$stringText"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- }}} -->

  <xsl:template match="/">
    <xsl:element name="root">
      <xsl:apply-templates select="//flow:execute/flow:*"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="attr2node">
    <!-- {{{ -->
    <xsl:for-each select="@*[name() != 'id' and name() != 'endpoint' and name() != 'serviceoperation' and name() != 'repository' and name() != 'injection' and name() != 'method']">
      <xsl:variable name="qname" select="name()"/>
      <xsl:element name="{$qname}">
        <xsl:value-of select="."/>
      </xsl:element>
    </xsl:for-each>
    <!-- }}} -->
  </xsl:template>

  <xsl:template name="copy-attr">
    <!-- {{{ --> 
    <xsl:for-each select="@*">
      <xsl:variable name="qname" select="name()"/>
      <xsl:attribute name="{$qname}">
        <xsl:value-of select="."/>
      </xsl:attribute>
    </xsl:for-each>
    <!-- }}} -->
  </xsl:template>

  <xsl:template name="resolve-variable">
    <!-- {{{ -->
    <xsl:param name="var" select="@variable"/>
    <xsl:choose>
      <xsl:when test="(//context-variables/*[name()=$var])">
        <xsl:text>context[:"</xsl:text>
        <xsl:value-of select="$var"/>
        <xsl:text>"]</xsl:text>
      </xsl:when>
      <xsl:when test="//endpoints/*[name()=$var]">
        <xsl:text>endpoints[:"</xsl:text>
        <xsl:value-of select="$var"/>
        <xsl:text>"]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="starts-with($var, '@') = false">
          <xsl:text>@</xsl:text>
        </xsl:if>
        <xsl:value-of select="$var"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:copy">
    <!-- {{{ -->
<!--
    <xsl:text>&lt;xsl:variable name=&quot;</xsl:text>
    <xsl:value-of select="@xsl-name"/>
    <xsl:text>&quot; select=&quot;#{</xsl:text>
    <xsl:call-template name="resolve-variable">
      <xsl:with-param name="var" select="@variable"/>
    </xsl:call-template>
    <xsl:text>}&quot;&gt;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
-->
    <!-- }}} -->
  </xsl:template>

  <xsl:template name="constraint">
    <!-- {{{ --> 
    <xsl:element name="constraint">
      <xsl:for-each select="child::flow:constraint">
        <xsl:variable name="name" select="generate-id()"/>
        <xsl:element name="{$name}">
          <xsl:call-template name="attr2node"/>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
    <!-- }}} -->
  </xsl:template>

  <xsl:template name="input">
    <!-- {{{ -->
    <xsl:element name="parameters">
      <xsl:for-each select="child::flow:input">
        <xsl:variable name="qname" select="@name"/>
        <xsl:element name="{$qname}">
          <xsl:if test="@variable">
            <xsl:call-template name="resolve-variable">
              <xsl:with-param name="var" select="@variable"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="@message-parameter">
            <xsl:if test="starts-with(@message-parameter, '@') = false">
              <xsl:text>@</xsl:text>
            </xsl:if>
            <xsl:value-of select="@message-parameter"/>
          </xsl:if>
          <xsl:if test="@fix-value">
            <xsl:value-of select="@fix-value"/>
          </xsl:if>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
<!--
    <xsl:param name="input" select="child::flow:input"/>
    <xsl:for-each select="$input">
      <xsl:variable name="id" select="generate-id()"/>
      <xsl:choose>
        xsl:when test="string(@transformation-uri)">
          <xsl:text>&#xa;</xsl:text>
          <xsl:text>parallel_branch do&#xa;</xsl:text>
          <xsl:text>var_</xsl:text>
          <xsl:value-of select="$id"/>
          <xsl:text> = nil&#xa;</xsl:text>
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
            <xsl:call-template name="xml-to-string">
              <xsl:with-param name="node-set" select="child::xsl:*"/>
            </xsl:call-template>
            <xsl:text>&#xa;XSLT&#xa;</xsl:text>
          <xsl:text>}</xsl:text>
          <xsl:text> do |result|&#xa;</xsl:text>
            <xsl:text>  var_</xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text> = result.values[0]&#xa;</xsl:text>
          <xsl:text>end&#xa;</xsl:text>
          <xsl:text>input[:</xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:text>] = </xsl:text>
          <xsl:text>var_</xsl:text>
          <xsl:value-of select="$id"/>
          <xsl:text>&#xa;</xsl:text>
          <xsl:text>end&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&#xa;</xsl:text>
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
-->
    <!-- }}} --> 
  </xsl:template>

  <xsl:template name="output">
    <!-- {{{ -->
    <xsl:element name="manipulate">
      <xsl:attribute name="output">
        <xsl:text>result</xsl:text>
      </xsl:attribute>
      <xsl:for-each select="child::flow:resource-id">
        <xsl:text>endpoints[:</xsl:text>
        <xsl:value-of select="@endpoint"/>
        <xsl:text>] = result.value('</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>')&#xa;</xsl:text>
      </xsl:for-each>
      <xsl:for-each select="child::flow:output">
        <xsl:choose>
          <xsl:when test="@variable and @name">
            <xsl:element name="output">
              <xsl:attribute name="variable"><xsl:value-of select="@variable"/></xsl:attribute>
              <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="@message-parameter != ''">
                <xsl:if test="starts-with(@message-parameter, '@') = false">
                  <xsl:text>@</xsl:text>
                </xsl:if>
                <xsl:value-of select="@message-parameter"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="resolve-variable">
                  <xsl:with-param name="var" select="@variable"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text> = </xsl:text>
            <xsl:choose>
              <xsl:when test="@variable and @message-parameter != ''">
                <xsl:call-template name="resolve-variable">
                  <xsl:with-param name="var" select="@variable"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="@fix-value">
                <xsl:value-of select="@fix-value"/>
              </xsl:when>
              <xsl:when test="@name">
                <xsl:text>result.value('</xsl:text>
                <xsl:value-of select="@name"/>
                <xsl:text>')</xsl:text>
                <xsl:if test="not(@type) or (@type != 'simple')">
                  <xsl:text>.read</xsl:text>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text># ERROR</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#xa;</xsl:text>
      </xsl:for-each>
    </xsl:element>
    <!--  }}} -->
  </xsl:template>

  <xsl:template match="//flow:call">
    <!-- {{{ -->
    <xsl:element name="call">
      <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      <xsl:attribute name="endpoint"><xsl:value-of select="@endpoint"/></xsl:attribute>
      <xsl:element name="parameters">
        <xsl:if test="@http-method">
          <xsl:element name="method"><xsl:value-of select="@http-method"/></xsl:element>
        </xsl:if>
        <xsl:if test="@service-operation">
          <xsl:element name="service">
            <xsl:element name="serviceoperation">"<xsl:value-of select="@service-operation"/>"</xsl:element>
            <xsl:element name="injection"><xsl:value-of select="@injection"/></xsl:element>
          </xsl:element>
        </xsl:if>
        <xsl:if test="@group-by">
          <xsl:element name="group">
            <xsl:element name="group_by"><xsl:text>&quot;</xsl:text><xsl:value-of select="@group-by"/><xsl:text>&quot;</xsl:text></xsl:element>
            <xsl:element name="uri_xpath"><xsl:text>&quot;</xsl:text><xsl:value-of select="child::flow:resource-id/@xpath"/><xsl:text>&quot;</xsl:text></xsl:element>
            <!-- xsl:variable name="ep_name" select="child::flow:resource-id/@name"/>
            <xsl:element name="{$ep_name}"><xsl:text>&quot;</xsl:text><xsl:value-of select="child::flow:resource-id/@endpoint"/><xsl:text>&quot;</xsl:text></xsl:element -->
          </xsl:element>
        </xsl:if>
        <xsl:if test="child::flow:constraint">
          <xsl:call-template name="constraint"/>
        </xsl:if>
        <xsl:if test="child::flow:input">
          <xsl:call-template name="input"/>
        </xsl:if>
      </xsl:element>
      <xsl:if test="child::flow:output">
        <xsl:call-template name="output"/>
      </xsl:if>
    </xsl:element>
     <!-- }}} --> 
  </xsl:template>

  <xsl:template match="//flow:instruction">
    <!-- {{{ -->
    <xsl:choose>
      <xsl:when test="@message-parameter">
        <xsl:value-of select="@message-parameter"/>
        <xsl:if test="starts-with(@message-parameter, '@') != 'true'">
          <xsl:text>@</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="resolve-variable">
          <xsl:with-param name="var" select="@variable"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> = </xsl:text>
    <xsl:choose>
      <xsl:when test="@variable and @message-parameter">
        <xsl:call-template name="resolve-variable">
          <xsl:with-param name="var" select="@variable"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@fix-value">
        <xsl:value-of select="@fix-value"/>
      </xsl:when>
      <xsl:when test="@name">
        <xsl:text>result.value('</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>')</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text># ERROR</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
<!--     
    <xsl:param name="mode"/>
    <xsl:variable name="var" select="@variable"/>
    <xsl:variable name="target" select="@target"/>
    <xsl:choose>
      <xsl:when test="($mode = 'transform') and (child::xsl:*)">
        <xsl:text>&#xa;</xsl:text>
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
          <xsl:call-template name="xml-to-string">
            <xsl:with-param name="node-set" select="child::xsl:*"/>
          </xsl:call-template>
          <xsl:text>&#xa;XSLT&#xa;</xsl:text>
        <xsl:text>}</xsl:text>
        <xsl:text> do |result|&#xa;</xsl:text>
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
        <xsl:call-template name="resolve-variable">
          <xsl:with-param name="var" select="@target"/>
        </xsl:call-template>
        <xsl:text> = </xsl:text>
        <xsl:value-of select="generate-id()"/>
      </xsl:otherwise>
    </xsl:choose>
-->    
    <!-- }}} -->  
  </xsl:template>

  <xsl:template match="//flow:manipulate">
     <!-- {{{ -->
    <xsl:element name="manipulate">
      <xsl:call-template name="copy-attr"/>
      <xsl:apply-templates name="child::flow:instruction"/>
    </xsl:element>
    <!-- }}} -->  
  </xsl:template>
  
  <xsl:template match="//flow:critical">
    <!-- {{{ -->
    <xsl:element name="cirtical">
      <xsl:call-template name="copy-attr"/>
      <xsl:apply-templates select="child::flow:*"/>
    </xsl:element>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:parallel">
    <!-- {{{ -->
    <xsl:element name="parallel">
      <xsl:call-template name="copy-attr"/>
      <xsl:apply-templates select="child::flow:*"/>
    </xsl:element>
    <!-- }}} --> 
  </xsl:template>
  
  <xsl:template match="//flow:parallel_branch">
    <!-- {{{ -->  
    <xsl:element name="parallel_branch">
      <xsl:call-template name="copy-attr"/>
      <xsl:apply-templates select="child::flow:*"/>
    </xsl:element>
     <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:loop">
    <!-- {{{ -->
    <xsl:element name="loop">
      <xsl:attribute name="pre_test">
        <xsl:apply-templates select="child::flow:group"/>
        <xsl:apply-templates select="child::flow:condition"/>
      </xsl:attribute>
      <xsl:apply-templates select="child::flow:*[(name() != 'group') and (name() != 'condition')]"/>
    </xsl:element>
     <!-- }}} -->
  </xsl:template>

  <xsl:template match="//flow:choose">
    <!-- {{{ -->
    <xsl:element name="choose">
      <xsl:apply-templates select="child::flow:alternative"/>
      <xsl:apply-templates select="child::flow:otherwise"/>
    </xsl:element>
     <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:alternative">
    <!-- {{{ -->
    <xsl:element name="alternative">
      <xsl:attribute name="condition">
        <xsl:apply-templates select="child::flow:group"/>
        <xsl:apply-templates select="child::flow:condition"/>
      </xsl:attribute>
      <xsl:apply-templates select="child::flow:*[(name() != 'group') and (name() != 'condition')]"/>
    </xsl:element>
    <!-- }}} -->
  </xsl:template>
  
  <xsl:template match="//flow:otherwise">
    <!-- {{{ -->
    <xsl:element name="otherwise">
      <xsl:apply-templates select="child::flow:*"/>
    </xsl:element>
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
</xsl:stylesheet>
<!-- }}} -->
