<!DOCTYPE html>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" doctype-public="XSLT-compat"/>
  <xsl:template match="*">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
      <head>
         <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
         <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"/>
         <title>CPEE - PGWL</title>
      </head>
      <body>
        <h1>Poor Guys WorkList</h1>
        <table>
          <tr><td colspan="3"><h2>Entries</h2></td></tr>
          <xsl:for-each select="//instance">
            <tr>
              <td>CPEE - Instance:</td><td colspan="2"><xsl:element name="a"><xsl:attribute name="href"><xsl:value-of select="@uri"/></xsl:attribute><xsl:attribute name="target">_blank</xsl:attribute><xsl:value-of select="@uri"/></xsl:element></td>
            </tr>
            <tr><td> </td></tr>
              <xsl:for-each select="child::*">
                <tr>
                  <td> </td>
                  <td>Activity-ID:</td><td><xsl:value-of select="name()"/></td>
                  </tr>
                  <tr>
                  <td> </td>
                  <td><xsl:element name="a">
                      <xsl:attribute name="href">?instance=<xsl:value-of select="parent::instance/@uri"/>&amp;activity=<xsl:value-of select="name()"/>&amp;name=<xsl:value-of select="child::template-name"/>&amp;lang=<xsl:value-of select="child::template-lang"/>
                      </xsl:attribute>
                      Go to task
                    </xsl:element>
                  </td>
                </tr>
              </xsl:for-each>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
