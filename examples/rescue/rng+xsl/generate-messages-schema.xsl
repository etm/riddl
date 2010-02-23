<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:group="http://rescue.org/ns/group/0.2"
  xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  >

 <xsl:output method="xml"/>

  <xsl:template match="/">
    <grammar xmlns="http://relaxng.org/ns/structure/1.0" datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes"><xsl:text>&#10;</xsl:text>
      <start><xsl:text>&#10;</xsl:text>
        <xsl:for-each select="/group:interface/group:operations/group:*/*">
        <xsl:call-template name="message"/>
        </xsl:for-each>
      </start><xsl:text>&#10;</xsl:text>
    </grammar>
  </xsl:template>

  
  <xsl:template name="message">
    <xsl:element name="element">
      <xsl:attribute name="name">
        <xsl:value-of select="name(parent::*)"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="name()"/>
      </xsl:attribute>
    <xsl:call-template name="params"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="params">
    <xsl:for-each select="*">
      <xsl:element name="element">
        <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
        <xsl:copy-of select="./rng:data"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
