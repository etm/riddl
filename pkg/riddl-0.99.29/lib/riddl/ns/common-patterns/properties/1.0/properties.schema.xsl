<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns="http://relaxng.org/ns/structure/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:p="http://riddl.org/ns/common-patterns/properties/1.0">
  <xsl:output method="xml" indent="yes"/>

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

      <define name="arbitrary">
        <zeroOrMore>
          <choice>
            <text/>
            <ref name="any"/>
          </choice>
        </zeroOrMore>
      </define>

      <define name="any">
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

  <xsl:template match="*[name()!='optional']">
    <element>

      <xsl:attribute name="name">
        <xsl:value-of select="name()"/>
      </xsl:attribute>

      <xsl:if test="@type='arbitrary'">
        <ref name="arbitrary"/>
      </xsl:if>
        
      <xsl:if test="@type='complex'">
        <xsl:apply-templates mode="copy-no-ns"/>
      </xsl:if>  

      <xsl:if test="@type='state'">
        <choice>
          <xsl:for-each select='*'>
            <value><xsl:value-of select='name()'/></value>
          </xsl:for-each>
        </choice>
      </xsl:if>

      <xsl:if test="@type='simple'">
        <xsl:apply-templates mode="copy-no-ns"/>
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
