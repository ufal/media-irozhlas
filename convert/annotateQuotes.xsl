<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="xs tei" >

  <xsl:param name="outDir"/>
  <xsl:param name="anaFile"/>
  <xsl:output method="xml" indent="no" encoding="UTF-8" />
  <xsl:variable name="anaType">QUOTATION</xsl:variable>

  <xsl:variable name="newAna">
    <xsl:choose>
      <xsl:when test="normalize-space($anaFile) and not(doc-available(concat(replace(document-uri(/), '(.+)/[^/]*\.xml', '$1'),'/',$anaFile)))">
        <xsl:message terminate="no">
          <xsl:text>WARN: ana document </xsl:text>
          <xsl:value-of select="concat(replace(document-uri(/), '(.+)/[^/]*\.xml', '$1'),'/',$anaFile)"/>
          <xsl:text> not available!</xsl:text>
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <Q>
          <xsl:for-each select="document(concat(replace(document-uri(/), '(.+)/[^/]*\.xml', '$1'),'/',$anaFile))/teiQuotes/quote">
            <xsl:variable name="quotePos" select="position()"/>
            <quote n="{$quotePos}">
              <xsl:variable name="name" select="normalize-space(concat(./firstName/text(),' ',./surname/text()))"/>
              <xsl:if test="$name">
                <xsl:variable name="sortedName">
                  <xsl:for-each select="tokenize($name)">
                    <xsl:sort select="number(substring-after(.,'.w'))" data-type="number"/> <!-- expecting the same sentence -->
                    <xsl:value-of select="."/><xsl:text> </xsl:text>
                  </xsl:for-each>
                </xsl:variable>
                <name><xsl:value-of select="normalize-space($sortedName)"/></name>
              </xsl:if>

              <xsl:copy-of select="./*[contains(' role statement institution ',local-name()) and normalize-space(./text())]"/>

            </quote>
          </xsl:for-each>
        </Q>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="docId" select="/*/@xml:id" />
  <xsl:variable name="existingMweCnt" select="count(//tei:span/@xml:id[starts-with(.,concat($docId,'.mwe'))])" />


  <xsl:variable name="spanGrp">
    <xsl:if test="count($newAna/*)>0">
      <spanGrp type="{$anaType}">
        <xsl:apply-templates select="$newAna//*[contains(' name role statement institution ',local-name())]" mode="anaSpan"/>
      </spanGrp>
    </xsl:if>
  </xsl:variable>

  <xsl:template match="tei:text">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="tei:*|text()"/>
      <!-- inserting annotation -->
      <xsl:if test="$spanGrp/*">
        <xsl:apply-templates select="$spanGrp" mode="printSpan"/>
        <linkGrp type="{$anaType}" targFunc="statement source">
          <xsl:apply-templates select="$newAna//*[contains(' name role institution ',local-name())]" mode="anaLink"/>
        </linkGrp>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:name | *:institution | *:role | *:statement" mode="anaSpan">
    <!-- including one word statements -->
    <xsl:variable name="n" select="count(preceding::*[parent::*:quote]) +1"/>
    <xsl:element name="span">
      <xsl:attribute name="ana" select="concat('quote:',local-name())"/>
      <xsl:attribute name="xml:id" select="concat($docId,'.mwe',$n+$existingMweCnt)"/>
      <xsl:attribute name="target" select="./text()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*:name | *:institution | *:role " mode="anaLink">
    <!-- including one word statements -->
    <xsl:variable name="sourceName" select="./local-name()"/>
    <xsl:variable name="sourceTarget" select="./text()"/>
    <xsl:variable name="statementTarget" select="parent::*/statement/text()"/>
    <xsl:variable name="sourceSpan" select="$spanGrp//*[@target=$sourceTarget]"/>
    <xsl:variable name="statementSpan" select="$spanGrp//*[@target=$statementTarget]"/>

    <xsl:element name="link">
      <xsl:attribute name="target" select="concat('#',$statementSpan/@xml:id,' #',$sourceSpan/@xml:id)"/>
    </xsl:element>

  </xsl:template>

  <xsl:template match="tei:*[not(local-name()='text')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="tei:*|text()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="*:spanGrp" mode="printSpan">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="printSpan"/>
      <xsl:apply-templates select="*" mode="printSpan"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*" mode="printSpan">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="printSpan"/>
      <xsl:apply-templates select="*|text()" mode="printSpan"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*" mode="printSpan">
    <xsl:copy/>
  </xsl:template>
</xsl:stylesheet>