<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:group="http://rescue.org/ns/group/0.2"
  xmlns="http://relaxng.org/ns/structure/1.0"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:service="http://rescue.org/ns/service/0.2"
  xmlns:wf="http://rescue.org/ns/workflow/0.2">

  <xsl:output method="xml"/>

  <xsl:template match="/">
    <grammar xmlns="http://relaxng.org/ns/structure/1.0" 
              datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes" 
              xmlns:service="http://rescue.org/ns/service/0.2" 
              xmlns:wf="http://rescue.org/ns/workflow/0.2">
      <xsl:copy-of select="document('workflow.rng')/rng:grammar/rng:define[@name='context']"/>
      <xsl:copy-of select="document('workflow.rng')/rng:grammar/rng:define[@name='endpoint']"/>
      <xsl:copy-of select="document('workflow.rng')/rng:grammar/rng:define[@name='activity']"/>
      <start>
        <element name="service:service-details"><xsl:text>&#10;</xsl:text>
          <element name="service:properties"><xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="/group:interface/group:properties/rng:element"/>
          </element><xsl:text>&#10;</xsl:text>
          <element name="service:operations"><xsl:text>&#10;</xsl:text>
            <xsl:apply-templates select="/group:interface/group:operations/group:*"/>
          </element><xsl:text>&#10;</xsl:text>
        </element><xsl:text>&#10;</xsl:text>
      </start>
    </grammar>
    <!--/xsl:element-->
  </xsl:template>

  <xsl:template match="/group:interface/group:operations/group:*">
    <xsl:element name="element"><xsl:attribute name="name"><xsl:text>service:</xsl:text><xsl:value-of select="name()"/></xsl:attribute>
      <element name="wf:execution">
        <xsl:copy-of select="document('workflow.rng')/rng:grammar/rng:define[@name='workflow']/*" />
      </element>
    </xsl:element><xsl:text>&#10;</xsl:text>
  </xsl:template>


  <xsl:template match="/group:interface/group:properties/rng:element">
    <xsl:element name="element"><xsl:attribute name="name"><xsl:text>service:</xsl:text><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="./rng:data"/>
    </xsl:element><xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template name="in-out">
    <optional>
      <element name="service:call-input-message">
        <zeroOrMore><xsl:text>&#10;</xsl:text>
          <element name="service:parameter">
            <choice><xsl:text>&#10;</xsl:text>
              <attribute name="name"/><xsl:text>&#10;</xsl:text>
              <optional><xsl:text>&#10;</xsl:text>
                <attribute name="value"/><xsl:text>&#10;</xsl:text>
              </optional><xsl:text>&#10;</xsl:text>
            </choice><xsl:text>&#10;</xsl:text>
          </element><xsl:text>&#10;</xsl:text>
        </zeroOrMore><xsl:text>&#10;</xsl:text>
      </element>
    </optional>
    <optional>
      <element name="service:call-output-message">
        <zeroOrMore><xsl:text>&#10;</xsl:text>
          <element name="service:parameter">
            <choice><xsl:text>&#10;</xsl:text>
              <attribute name="name"/><xsl:text>&#10;</xsl:text>
              <optional><xsl:text>&#10;</xsl:text>
                <attribute name="value"/><xsl:text>&#10;</xsl:text>
              </optional><xsl:text>&#10;</xsl:text>
            </choice><xsl:text>&#10;</xsl:text>
          </element><xsl:text>&#10;</xsl:text>
        </zeroOrMore><xsl:text>&#10;</xsl:text>
      </element>
    </optional>
  </xsl:template>

</xsl:stylesheet>

