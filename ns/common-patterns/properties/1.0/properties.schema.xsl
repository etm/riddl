<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:p="http://riddl.org/ns/common-patterns/properties/1.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/p:properties">
    <element name="properties" xmlns="http://relaxng.org/ns/structure/1.0" datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes" ns="http://riddl.org/ns/common-patterns/properties/1.0">
      <interleave>
        <xsl:apply-templates select="./*[name()!='optional']"/>
        <xsl:apply-templates select="p:optional"/>
      </interleave>
    </element>  
  </xsl:template>

  <xsl:template match="p:optional">
    <xsl:element name="optional" namespace="http://relaxng.org/ns/structure/1.0">
      <xsl:apply-templates select="./*[name()!='optional']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*[name()!='optional']">
    <xsl:element name="element" namespace="http://relaxng.org/ns/structure/1.0">

      <xsl:attribute name="name">
        <xsl:value-of select="name()"/>
      </xsl:attribute>

      <xsl:if test="@type='map'">
        <xsl:element name="externalRef" namespace="http://relaxng.org/ns/structure/1.0">
          <xsl:attribute name="href">http://riddl.org/ns/common-patterns/properties/1.0/map.rng</xsl:attribute>
        </xsl:element>
      </xsl:if>

      <xsl:if test="@type='list'">
        <xsl:element name="externalRef" namespace="http://relaxng.org/ns/structure/1.0">
          <xsl:attribute name="href">http://riddl.org/ns/common-patterns/properties/1.0/list.rng</xsl:attribute>
        </xsl:element>
      </xsl:if>
      
      <xsl:if test="@type='content'">
        <xsl:element name="externalRef" namespace="http://relaxng.org/ns/structure/1.0">
          <xsl:attribute name="href">http://riddl.org/ns/common-patterns/properties/1.0/arbitrary.rng</xsl:attribute>
        </xsl:element>
      </xsl:if>

      <xsl:if test="@type='value'">
        <xsl:apply-templates mode="copy-no-ns"/>
      </xsl:if>

    </xsl:element>
  </xsl:template>

  <xsl:template mode="copy-no-ns" match="*">
    <xsl:element name="{name(.)}" namespace="http://relaxng.org/ns/structure/1.0">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="copy-no-ns"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
