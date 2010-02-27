<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:group="http://rescue.org/ns/group/0.2"
  xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:service="http://rescue.org/ns/service/0.2"
  xmlns:exec="http://rescue.org/ns/execution/0.2"
  xmlns:wf="http://rescue.org/ns/workflow/0.2">

  <xsl:output method="xml"/>

  <xsl:template match="/">
    <grammar xmlns="http://relaxng.org/ns/structure/1.0" 
              datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes" 
              xmlns:service="http://rescue.org/ns/service/0.2" 
              xmlns:exec="http://rescue.org/ns/execution/0.2">
      <xsl:copy-of select="document('execution.rng')/rng:grammar/rng:define[@name='context']"/>
      <xsl:copy-of select="document('execution.rng')/rng:grammar/rng:define[@name='endpoint']"/>
      <xsl:copy-of select="document('execution.rng')/rng:grammar/rng:define[@name='call']"/>
      <start>
        <element name="service:service-details"><xsl:text>&#10;</xsl:text>
          <element name="service:properties"><xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="/group:interface/group:properties/rng:element"/>
          </element><xsl:text>&#10;</xsl:text>
          <element name="service:methods"><xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="/group:interface/group:methods/group:method"/>
          </element><xsl:text>&#10;</xsl:text>
        </element><xsl:text>&#10;</xsl:text>
      </start>
    </grammar>
    <!--/xsl:element-->
  </xsl:template>

  <xsl:template match="/group:interface/group:methods/group:method">
    <xsl:element name="element"><xsl:attribute name="name"><xsl:text>service:</xsl:text><xsl:value-of select="@name"/></xsl:attribute>
      <element name="service:execution">
        <xsl:copy-of select="document('execution.rng')/rng:grammar/rng:start/rng:element[@name='exec:execution-plan']/*" />
      </element>
    </xsl:element><xsl:text>&#10;</xsl:text>
  </xsl:template>


  <xsl:template match="/group:interface/group:properties/rng:element">
    <xsl:element name="element"><xsl:attribute name="name"><xsl:text>service:</xsl:text><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="./rng:data"/>
    </xsl:element><xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>

