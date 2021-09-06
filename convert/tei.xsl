<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0">
  <xsl:output method="xml" indent="yes" encoding="utf-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="*"  mode="html"/>

  <xsl:template match="/ROOT">
    <TEI>
      <xsl:attribute name="xml:id">doc-<xsl:value-of select="./id"/></xsl:attribute>
      <teiHeader>
        <fileDesc>
          <titleStmt>
            <title type="main" xml:lang="cs"><xsl:value-of select="./title/text()"/></title>
            <respStmt>
              <persName ref="https://orcid.org/0000-0001-7953-8783">Matyáš Kopp</persName>
              <resp xml:lang="en">TEI XML corpus encoding</resp>
              <resp xml:lang="en">Linguistic annotation</resp>
            </respStmt>
          </titleStmt>
          <editionStmt>
            <edition>1.0</edition>
          </editionStmt>
          <sourceDesc>
            <bibl>
              <title type="main" xml:lang="cs"><xsl:value-of select="./title/text()"/></title>
              <xsl:apply-templates select="./authors/ITEM" />
              <idno type="URI"><xsl:value-of select="./url" /></idno>
              <date>
                <xsl:attribute name="when"><xsl:value-of select="translate(./changed/text(),' ','T')"/></xsl:attribute>
                <xsl:value-of select="./changed" />
              </date>
              <xsl:apply-templates select="./sections/ITEM" />
              <xsl:apply-templates select="./tags/ITEM" />
            </bibl>
          </sourceDesc>
        </fileDesc>
      </teiHeader>
      <text>
        <xsl:apply-templates select="./perex" />
        <xsl:apply-templates select="./text" />
      </text>
    </TEI>
  </xsl:template>
  <xsl:template match="ITEM[./parent::authors]">
    <xsl:element name="author">
      <xsl:attribute name="sameAs">pers-<xsl:value-of select="./id"/></xsl:attribute>
      <xsl:element name="persName"><xsl:value-of select="./name" /></xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="title">
    <xsl:element name="head">
      <xsl:attribute name="type">title</xsl:attribute>
      <xsl:value-of select="./text()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="ITEM[./parent::sections]">
    <xsl:element name="idno">
      <xsl:attribute name="type">section</xsl:attribute>
      <xsl:attribute name="sameAs">sect-<xsl:value-of select="./tid"/></xsl:attribute>
      <xsl:value-of select="./name" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="ITEM[./parent::tags]">
    <xsl:element name="idno">
      <xsl:attribute name="type">tag</xsl:attribute>
      <xsl:attribute name="sameAs">tag-<xsl:value-of select="./tid"/></xsl:attribute>
      <xsl:value-of select="./name" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="perex">
    <xsl:element name="front">
      <xsl:apply-templates select="../title"/>
      <xsl:element name="div">
        <xsl:attribute name="type">perex</xsl:attribute>
        <xsl:element name="seg">
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="text">
    <xsl:element name="body">
      <xsl:element name="div">
        <xsl:attribute name="type">text</xsl:attribute>
        <xsl:apply-templates select="./html/body/node()" mode="html" />
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="p[.//text()[normalize-space(string-length()) > 0 ] ]" mode="html">
    <xsl:element name="seg">
      <xsl:apply-templates select="./*|./text()" mode="paragraph" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="h2" mode="html">
    <xsl:element name="head">
      <xsl:attribute name="type">subtitle</xsl:attribute>
      <xsl:apply-templates select=".//text()" mode="paragraph" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="text()" mode="paragraph">
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>

  <xsl:template match="a[@href and not(./img) and text()]" mode="paragraph">
    <xsl:text> </xsl:text>
    <xsl:element name="ref">
      <xsl:attribute name="target"><xsl:value-of select="@href" /></xsl:attribute>
      <xsl:apply-templates select="text()" mode="paragraph" />
    </xsl:element>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="span|strong" mode="paragraph">
    <xsl:apply-templates select="*|text()" mode="paragraph" />
  </xsl:template>

  <xsl:template match="br" mode="paragraph">
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="*[contains(@class,'inline')]" mode="html">
    <xsl:message>removing inline</xsl:message>
  </xsl:template>
  <xsl:template match="*[contains(@class,'embed')]" mode="html">
    <xsl:message>removing embed</xsl:message>
  </xsl:template>

</xsl:stylesheet>