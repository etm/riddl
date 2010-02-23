<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

 <xsl:output method="xml"/>

  <xsl:template match="/">
    <xsl:element name="grammar">
      <xsl:attribute name="xmlns">http://relaxng.org/ns/structure/1.0</xsl:attribute>
      <xsl:attribute name="datatypeLibrary">http://www.w3.org/2001/XMLSchema-datatypes</xsl:attribute>
      <!-- xsl:element name="include"><xsl:attribute name="href">relaxng-modular.rng</xsl:attribute></xsl:element -->
      <xsl:element name="start">
        <xsl:apply-templates select="/interface/operations/*"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="/interface/operations/*/*">
    <xsl:call-template name="message"/>
  </xsl:template>
  
  <xsl:template name="message">
    <xsl:element name="element">
      <xsl:attribute name="name">
        <xsl:value-of select="name(parent::*)"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>-message</xsl:text>
      </xsl:attribute>
    <xsl:call-template name="params"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="params">
    <xsl:for-each select="*">
      <xsl:element name="element">
        <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
        <xsl:copy-of select="./data"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
