<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns="http://relaxng.org/ns/structure/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:p="http://riddl.org/ns/common-patterns/properties/1.0">
  <xsl:output indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/p:properties">
    <grammar xmlns="http://relaxng.org/ns/structure/1.0" datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes" ns="http://riddl.org/ns/common-patterns/properties/1.0">

      <start>
        <element name="properties">
          <interleave>
            <xsl:apply-templates select="./*[name()!='optional']"/>
            <xsl:apply-templates select="p:optional"/>
          </interleave>
        </element>
      </start>

      <define name="xml">
        <element>
          <anyName/>
          <zeroOrMore>
            <attribute>
              <anyName/>
            </attribute>
          </zeroOrMore>
          <zeroOrMore>
            <choice>
              <text/>
              <ref name="any"/>
            </choice>
          </zeroOrMore>
        </element>
      </define>

    </grammar>
  </xsl:template>

  <xsl:template match="p:optional">
    <optional>
      <xsl:apply-templates select="./*[name()!='optional']"/>
    </optional>
  </xsl:template>

  <xsl:template mode="special" match="p:attribute">
    <attribute>
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:choose>
        <xsl:when test="@type">
          <data>
            <xsl:attribute name="type"><xsl:value-of select="@type"/></xsl:attribute>
            <xsl:apply-templates mode="special" select="p:choice"/>
          </data>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="special" select="p:choice"/>
        </xsl:otherwise>
      </xsl:choose>
    </attribute>
  </xsl:template>
  <xsl:template mode="special" match="p:choice">
    <choice>
       <xsl:apply-templates mode="special" select="p:value"/>
    </choice>
  </xsl:template>
  <xsl:template mode="special" match="p:value">
    <value><xsl:value-of select="text()"/></value>
  </xsl:template>
  <xsl:template mode="special" match="p:param">
    <param>
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:value-of select="text()"/>
    </param>
  </xsl:template>

  <xsl:template match="*[name()!='optional']">
    <element>

      <xsl:attribute name="name">
        <xsl:value-of select="name()"/>
      </xsl:attribute>

      <xsl:if test="@type='xml'">
        <ref name="xml"/>
      </xsl:if>

      <xsl:if test="@type='collection'">
        <xsl:apply-templates select="*"/>
      </xsl:if>

      <xsl:if test="@type='value'">
        <xsl:apply-templates mode="special" select="p:attribute"/>
        <xsl:apply-templates mode="special" select="p:choice"/>
        <xsl:if test="not(p:choice)">
          <data type="string"><xsl:apply-templates mode="special" select="p:param"/></data>
        </xsl:if>
      </xsl:if>

      <xsl:if test="@type='hash'">
        <element>
          <anyName/>
          <xsl:apply-templates mode="special" select="p:attribute"/>
          <xsl:apply-templates mode="special" select="p:choice"/>
          <xsl:if test="not(p:choice)">
            <data type="string"><xsl:apply-templates mode="special" select="p:param"/></data>
          </xsl:if>
        </element>
      </xsl:if>

      <xsl:if test="@type='state'">
        <optional>
          <attribute name="changed">
            <data type="dateTime"/>
          </attribute>
        </optional>
        <choice>
          <xsl:for-each select='*'>
            <value><xsl:value-of select='name()'/></value>
          </xsl:for-each>
        </choice>
      </xsl:if>

    </element>
  </xsl:template>

  <xsl:template mode="copy-no-ns" match="*">
    <xsl:element name="{name(.)}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="copy-no-ns"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
