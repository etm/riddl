<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 
 <xsl:output method="xml"/>

  <xsl:template match="/">
    <xsl:element name="grammar">
      <xsl:attribute name="xmlns">http://relaxng.org/ns/structure/1.0</xsl:attribute>
      <xsl:attribute name="datatypeLibrary">http://www.w3.org/2001/XMLSchema-datatypes</xsl:attribute>
      <xsl:element name="start">
        <xsl:element name="element">
          <xsl:attribute name="name">queryOutputMessage</xsl:attribute>
          <xsl:apply-templates select="/properties/dynamic/queryOutput"/>
        </xsl:element>
      </xsl:element>
     </xsl:element>
  </xsl:template>

  <xsl:template match="/properties/dynamic/queryOutput">
    <xsl:element name="element">
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="child::data"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="//cation">
  <!-- remove all caption elements -->
  </xsl:template>


</xsl:stylesheet>

