<?xml version='1.0' encoding='UTF-8'?>
<!--
  Modification of script: Erjavec, Tomaž. parlamint2connlu.xsl https://github.com/clarin-eric/ParlaMint/blob/8484b5e072976db8e36e029436df9c38ff7e3694/Scripts/parlamint2conllu.xsl
-->

<!-- Convert ParlaMint.ana to CoNLL-U:
     - document (u), paragraph (seg) and sentence (s) IDs
     - syntactic words (w/w)
     - XPoS (w/@ana)
     - UPoS and UD mophological features (w/@msd) and dependencies (s/linkGrp)
     - SpaceAfter (w/@join)
     - NER (name/@type)
 -->
<xsl:stylesheet version='2.0' 
  xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="#all">

  <xsl:output encoding="utf-8" method="text"/>
  <xsl:template match="tei:bibl/tei:note">
    <xsl:value-of select="concat('# ',./@type,' = |')"/>
    <xsl:value-of select="string-join(./tei:tag/text(),'|')"/>
    <xsl:value-of select="concat('|', '&#10;')"/>
  </xsl:template>

  <xsl:template match="tei:bibl/tei:district">
    <xsl:value-of select="concat('# domicil = ',., '&#10;')"/>
  </xsl:template>

  <xsl:template match="tei:bibl">
    <xsl:apply-templates/>
    <xsl:value-of select="'# author = |'"/>
    <xsl:value-of select="string-join(./tei:author/tei:persName/text(),'|')"/>
    <xsl:value-of select="concat('|', '&#10;')"/>
    <xsl:value-of select="concat('# date = ',./tei:date/@when, '&#10;')"/>
  </xsl:template>

  <xsl:template match="tei:text">
    <xsl:value-of select="concat('# stats = |words=', count(.//tei:w[not(@norm)]),'|sentences=',count(.//tei:s),'|paragraphs=',count(.//tei:head|//tei:p|//tei:cell|//tei:li),'|', '&#10;')"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()"/>
  <xsl:template match="text()" mode="sentence"/>

  <!-- A segment corresponds to a paragraph -->
  <xsl:template match="tei:head|tei:p|tei:cell|tei:li">
  	 <xsl:apply-templates select="tei:s"/>
  </xsl:template>
  
  <!-- And a sentence is a sentence -->
  <xsl:template match="tei:s">
    <xsl:apply-templates select="*" mode="sentence"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="*" mode="sentence">
    <xsl:apply-templates select="*" mode="sentence"/>
  </xsl:template>

  <xsl:template match="tei:w | tei:pc" mode="sentence">
    <xsl:value-of select="text()"/>
    <xsl:choose>
      <xsl:when test="not(@join = 'right')">
        <xsl:value-of select="' '"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
