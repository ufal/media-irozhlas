<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs" >

  <xsl:param name="outDir"/>
  <xsl:output method="xml" indent="yes" encoding="UTF-8" />

  <xsl:variable name="doc-id-list" select="distinct-values(//quote/@doc)"/>
  <xsl:variable name="root" select="/" />

  <xsl:template match="/teiQuotes">
    <xsl:for-each select="$doc-id-list">
      <xsl:variable name="id" select="."/>
      <xsl:variable name="path" select="concat($outDir,'/quote-',$id,'.xml')"/>
      <xsl:result-document href="{$path}" method="xml">
        <teiQuotes>
          <xsl:copy-of select="$root//quote[@doc=$id]" copy-namespaces="no"/>
        </teiQuotes>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="*|@*|text()"/>

</xsl:stylesheet>