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
        <xsl:for-each select="/group:interface/group:operations/group:operation">
          <xsl:element name="group:{@name}"><xsl:text>&#10;</xsl:text>
            <element name="input-message"><xsl:text>&#10;</xsl:text>
              <xsl:for-each select=".//descendant::group:execute">
              <xsl:variable name="m" select="@method"/>
              <!-- Select each input that is not an output of any preceding execute - but the line below doesn't work as it schould-->
                <xsl:apply-templates select ="//group:method[@name=$m]/group:input-message/rng:element[not(@name=//group:output-message/rng:element/@name)]"/>
              </xsl:for-each>
            </element><xsl:text>&#10;</xsl:text>
            
            <element name="output-message"><xsl:text>&#10;</xsl:text>
              <xsl:for-each select=".//descendant::group:execute">
              <xsl:variable name="m" select="@method"/>
                <xsl:choose>
                  <xsl:when test="(//group:method[@name=$m]/group:output-message[@type='single'])">
              <!-- Select each output that is not an input of any following execute - but the line below doesn't work as it schould-->
                    <xsl:apply-templates select ="//group:method[@name=$m]/group:output-message/rng:element[not(@name=//group:input-message/rng:element/@name)]"/>
                  </xsl:when>
                  <xsl:when test="(//group:method[@name=$m]/group:output-message[@type='list']) and (name(parent::group:*) = 'operation')">
                    <zeroOrMore><xsl:text>&#10;</xsl:text>
                      <xsl:element name="element">
                        <xsl:attribute name="name"><xsl:value-of select="//group:method[@name=$m]/group:output-message/@item-name"/></xsl:attribute><xsl:text>&#10;</xsl:text>
              <!-- Select each output that is not an input of any following execute - but the line below doesn't work as it schould-->
                        <xsl:apply-templates select ="//group:method[@name=$m]/group:output-message/rng:element"/>
                      </xsl:element><xsl:text>&#10;</xsl:text>
                    </zeroOrMore><xsl:text>&#10;</xsl:text>
                  </xsl:when>
                  <xsl:when test="(//group:method[@name=$m]/group:output-message[@type='list']) and (name(parent::group:*) = 'selection')">
              <!-- Select each output that is not an input of any following execute - but the line below doesn't work as it schould-->
                    <xsl:apply-templates select ="//group:method[@name=$m]/group:output-message/rng:element"/>
                  </xsl:when>
                </xsl:choose>
              </xsl:for-each>
            </element><xsl:text>&#10;</xsl:text>
          </xsl:element><xsl:text>&#10;</xsl:text>
        </xsl:for-each>
      </start><xsl:text>&#10;</xsl:text>
    </grammar>
  </xsl:template>


  <xsl:template match="//rng:element">
    <xsl:element name="rng:element">
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:copy-of select="./rng:data"/>
    </xsl:element><xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
