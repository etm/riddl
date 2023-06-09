<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:p="http://riddl.org/ns/common-patterns/properties/1.0">
  <xsl:output method="html" doctype-public="XSLT-compat"/>
  <xsl:template match="*">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
      <head>
         <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
         <title>List of Properties</title>
      </head>
      <body>
        <h1>List of Properties</h1>
        <ul>
          <xsl:for-each select="p:property">
            <li>
              <xsl:element name="a">
                <xsl:attribute name="href"><xsl:value-of select="text()"/>/</xsl:attribute>
                <xsl:value-of select="text()"/>
              </xsl:element>
            </li>  
          </xsl:for-each>
        </ul>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
