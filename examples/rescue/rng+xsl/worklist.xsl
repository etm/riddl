<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" doctype-public="XSLT-compat"/>
  <xsl:template match="*">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
      <head>
         <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
         <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"/>
         <title>CPEE - Worklist</title>
      </head>
      <body>
        <h1>Pending tasks</h1>
        <table>
          <xsl:for-each select="//instance">
            <tr>
              <td>Instance: </td><td><xsl:value-of select="@uri"/></td>
            </tr>
            <tr><td>
              <xsl:for-each select="child::*">
                <p>Activity: <xsl:value-of select="name()"/>
                  <xsl:element name="a">
                    <xsl:attribute name="href">?instance=<xsl:value-of select="parent::instance/@uri"/>&amp;activity=<xsl:value-of select="name()"/>&amp;name=<xsl:value-of select="child::template-name"/>&amp;lang=<xsl:value-of select="child::template-lang"/>
                    </xsl:attribute>
                    Show
                  </xsl:element>
                </p>
              </xsl:for-each>
            </td></tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
