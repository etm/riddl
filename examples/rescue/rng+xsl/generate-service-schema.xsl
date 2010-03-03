<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:service="http://rescue.org/ns/service/0.2"
  xmlns:domain="http://rescue.org/ns/domain/0.2"
  xmlns:exec="http://rescue.org/ns/execution/0.2">

  <xsl:output method="xml"/>

  <xsl:template match="/">
    <grammar xmlns="http://relaxng.org/ns/structure/1.0" 
              datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes" 
              xmlns:service="http://rescue.org/ns/service/0.2" 
              xmlns:exec="http://rescue.org/ns/execution/0.2">
      <xsl:copy-of select="document('execution.rng')/rng:grammar/rng:define"/>
      <xsl:text>&#10;</xsl:text><xsl:text>&#10;</xsl:text>
      <start>
        <element name="service:service-description"><xsl:text>&#10;</xsl:text>
          <element name="service:properties"><xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="/domain:domain-description/domain:properties/rng:element"/>
          </element><xsl:text>&#10;</xsl:text>
          <element name="service:methods"><xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="//exec:call[not(@service-method=preceding::exec:call/@service-method) and (@service-method != '')]"/>
          </element><xsl:text>&#10;</xsl:text>
        </element><xsl:text>&#10;</xsl:text>
      </start>
    </grammar>
    <!--/xsl:element-->
  </xsl:template>

  <xsl:template match="//exec:call">
    <element name="service:{@service-method}">
      <element name="service:execute">
        <ref name="execution-code"/>
      </element>
      <element name="service:compensate">
        <ref name="execution-code"/>
      </element>
      <element name="service:undo">
      <ref name="execution-code"/>
      </element>
      <element name="service:redo">
        <ref name="execution-code"/>
      </element>
      <element name="service:suspend">
        <ref name="execution-code"/>
      </element>
      <element name="service:abort">
        <ref name="execution-code"/>
      </element>
    </element><xsl:text>&#10;</xsl:text>
  </xsl:template>


  <xsl:template match="//domain:properties/rng:element">
    <xsl:element name="element"><xsl:attribute name="name"><xsl:text>service:</xsl:text><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="./rng:data"/>
    </xsl:element><xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>

