<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


  <xsl:output method="xml"/>

  <xsl:template match="/">
    <xsl:element name="grammar">
      <xsl:attribute name="xmlns">http://relaxng.org/ns/structure/1.0</xsl:attribute>
      <xsl:attribute name="datatypeLibrary">http://www.w3.org/2001/XMLSchema-datatypes</xsl:attribute>
      <xsl:element name="define">
        <xsl:attribute name="name">properties</xsl:attribute>
        <xsl:apply-templates select="/properties/dynamic/queryOutput/element"/>
      </xsl:element>

      <xsl:element name="start">
        <xsl:element name="element">
          <xsl:attribute name="name">queryOutputMessage</xsl:attribute>
            <xsl:element name="zeroOrMore">
              <xsl:element name="element">
                <xsl:attribute name="name">entry</xsl:attribute>
                <xsl:element name="ref">
                  <xsl:attribute name="name">properties</xsl:attribute>
                </xsl:element>
              </xsl:element>
            </xsl:element>
        </xsl:element>
      </xsl:element>
     </xsl:element>
  </xsl:template>

  <xsl:template match="/properties/dynamic/queryOutput/element">
    <xsl:element name="element">
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="child::data"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

