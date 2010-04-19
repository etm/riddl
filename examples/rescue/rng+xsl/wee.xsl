<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:flow="http://rescue.org/ns/controlflow/0.2">

  <xsl:output method="text"/>
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
    <xsl:apply-templates select="/testset/context-variables"/>
    <xsl:apply-templates select="/testset/endpoints"/>
    <xsl:apply-templates select="/testset/flow:description/flow:*"/>
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
    <xsl:apply-templates select="child::flow:*"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="prefix-whitespaces"/>
    <xsl:text>end</xsl:text>
    <!-- }}} --> 
  </xsl:template>
  
  <xsl:template match="//flow:parallel_branch">
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

  <xsl:template match="//context-variables">
     <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;  # ------ Define context-variables -----</xsl:text>
    <xsl:for-each select="child::*">
      <xsl:text>&#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>context:"</xsl:text><xsl:value-of select="name()"/><xsl:text>" => </xsl:text>
      <xsl:if test="not(string(text()))">
        <xsl:text> nil</xsl:text>
      </xsl:if>
      <xsl:value-of select="text()"/>
    </xsl:for-each>
    <!-- }}} --> 
  </xsl:template>

  <xsl:template match="//endpoints">
    <!-- {{{ -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;  # ------ Define endpoints-----</xsl:text>
    <xsl:for-each select="child::*">
      <xsl:text>&#xa;</xsl:text>
      <xsl:call-template name="prefix-whitespaces"/>
      <xsl:text>endpoint :"</xsl:text><xsl:value-of select="name()"/><xsl:text>" => </xsl:text>
      <xsl:if test="not(string(text()))">
        <xsl:text> nil</xsl:text>
      </xsl:if>
      <xsl:value-of select="text()"/>
    </xsl:for-each>
     <!-- }}} -->
  </xsl:template>

</xsl:stylesheet>
