<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 
 <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:text>&#xa;# Define context variables&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="//context"/>
    <xsl:text>&#xa;# Define enpoint variables&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="//activity/@serviceURI"/>
    <xsl:text>&#xa;# Define activities&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="//activity"/>
  </xsl:template>

  <!-- Template for context variables -->
  <xsl:template match="//context">
    <xsl:text>context :</xsl:text><xsl:value-of select="@id"/><xsl:text> => '</xsl:text><xsl:value-of select="text()"/><xsl:text>'&#xa;</xsl:text>
  </xsl:template>

  <!-- Template for endpoints variables -->
  <xsl:template match="//activity/@serviceURI">
    <xsl:variable name="id" select="../@id"/>
    <xsl:text>endpoint :e</xsl:text><xsl:value-of select="substring($id,2)"/><xsl:text> => '</xsl:text><xsl:value-of select="."/><xsl:text>'&#xa;</xsl:text>
  </xsl:template>

  <!-- Template for endpoints variables -->
  <xsl:template match="//activity">

    <xsl:text>activity :</xsl:text><xsl:value-of select="@id"/>, :<xsl:value-of select="@method"/><xsl:text>, :e</xsl:text><xsl:value-of select="substring(@id,2)"/>
    <xsl:apply-templates select="input"/>
    <xsl:text> do |</xsl:text>
    <xsl:for-each select="./context">
      <xsl:text></xsl:text><xsl:value-of select="@parameter"/>
      <xsl:if test="position()!=last()"><xsl:text>, </xsl:text></xsl:if>
    </xsl:for-each>
    <xsl:text>|</xsl:text>
    <xsl:for-each select="./context">
      <xsl:text>&#xa; </xsl:text><xsl:text>@</xsl:text><xsl:value-of select="@id"/><xsl:text> = </xsl:text><xsl:value-of select="@parameter"/>


      <xsl:text>&#xa; puts </xsl:text><xsl:text>@</xsl:text><xsl:value-of select="@id"/>
      <xsl:text>&#xa; puts </xsl:text><xsl:value-of select="@parameter"/>


    </xsl:for-each>
    <xsl:text>&#xa;end&#xa;&#xa;</xsl:text>
  </xsl:template>

  <!-- Template for activity inputs -->
  <xsl:template match="input">
    <xsl:text>, :</xsl:text><xsl:value-of select="@name"/><xsl:text> => @</xsl:text><xsl:value-of select="@context"/>
  </xsl:template>
</xsl:stylesheet>
