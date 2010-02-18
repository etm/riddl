<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

 <xsl:output method="xml"/>

  <xsl:template match="/">
    <xsl:element name="grammar">
      <xsl:attribute name="xmlns">http://relaxng.org/ns/structure/1.0</xsl:attribute>
      <xsl:attribute name="datatypeLibrary">http://www.w3.org/2001/XMLSchema-datatypes</xsl:attribute>
      <xsl:element name="start">
        <xsl:element name="element"><xsl:attribute name="name">service-details</xsl:attribute>
          <xsl:element name="element"><xsl:attribute name="name">properties</xsl:attribute>
            <xsl:apply-templates select="/interface/properties/element"/>
          </xsl:element>
          <xsl:text>&#10;</xsl:text>
          <xsl:element name="element"><xsl:attribute name="name">operations</xsl:attribute>
            <xsl:apply-templates select="/interface/operations/*"/>
          </xsl:element>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="/interface/operations/*">
    <xsl:text>&#10;</xsl:text>
    <!-- xsl:element name="optional" -->
      <xsl:element name="element"><xsl:attribute name="name"><xsl:value-of select="name()"/></xsl:attribute><xsl:text>&#10;</xsl:text>
        <xsl:element name="attribute"><xsl:attribute name="name">uri</xsl:attribute>
          <xsl:element name="text"/>
        </xsl:element>  
        <xsl:text>&#10;</xsl:text>
        <xsl:element name="attribute"><xsl:attribute name="name">http-method</xsl:attribute>
            <xsl:element name="choice">
              <xsl:element name="value">get</xsl:element>
              <xsl:element name="value">put</xsl:element>
              <xsl:element name="value">post</xsl:element>
              <xsl:element name="value">delete</xsl:element>
            </xsl:element>
        </xsl:element>
        <xsl:element name="zeroOrMore">
          <xsl:element name="element"><xsl:attribute name="name">pre</xsl:attribute>
            <xsl:element name="attribute"><xsl:attribute name="name">uri</xsl:attribute></xsl:element>
            <xsl:call-template name="in-out"/>
          </xsl:element>
        </xsl:element>
        <xsl:element name="zeroOrMore">
          <xsl:element name="element"><xsl:attribute name="name">post</xsl:attribute>
            <xsl:element name="attribute"><xsl:attribute name="name">uri</xsl:attribute></xsl:element>
            <xsl:call-template name="in-out"/>
          </xsl:element>
        </xsl:element>
      </xsl:element>
      <xsl:text>&#10;</xsl:text>
    <!-- /xsl:element -->
  </xsl:template>

  <xsl:template match="/interface/properties/element">
    <xsl:element name="element"><xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="./data"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="in-out">
    <xsl:element name="zeroOrMore">
      <xsl:element name="element"><xsl:attribute name="name">input</xsl:attribute>
        <xsl:element name="attribute"><xsl:attribute name="name">parameter-name</xsl:attribute></xsl:element>
      </xsl:element>
    </xsl:element>
    <xsl:element name="zeroOrMore">
      <xsl:element name="element"><xsl:attribute name="name">output</xsl:attribute>
        <xsl:element name="attribute"><xsl:attribute name="name">parameter-name</xsl:attribute></xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

