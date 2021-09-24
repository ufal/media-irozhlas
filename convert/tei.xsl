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
              <note type="section">
                <xsl:text>|</xsl:text>
                <xsl:apply-templates select="./sections/ITEM" />
              </note>
              <note type="tag">
                <xsl:text>|</xsl:text>
                <xsl:apply-templates select="./tags/ITEM" />
              </note>
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
      <xsl:attribute name="sameAs">#pers-<xsl:value-of select="./id"/></xsl:attribute>
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
    <xsl:element name="tag">
      <xsl:attribute name="sameAs">#sect-<xsl:value-of select="./tid"/></xsl:attribute>
      <xsl:value-of select="./name" />
    </xsl:element>
    <xsl:text>|</xsl:text>
  </xsl:template>

  <xsl:template match="ITEM[./parent::tags]">
    <xsl:element name="tag">
      <xsl:attribute name="sameAs">#tag-<xsl:value-of select="./tid"/></xsl:attribute>
      <xsl:value-of select="./name" />
    </xsl:element>
    <xsl:text>|</xsl:text>
  </xsl:template>

  <xsl:template match="perex">
    <xsl:element name="front">
      <xsl:apply-templates select="../title"/>
      <xsl:element name="div">
        <xsl:attribute name="type">perex</xsl:attribute>
        <xsl:element name="p">
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

  <xsl:template match="p[.//text()[string-length(normalize-space()) > 0 ] ]" mode="html">
    <xsl:element name="p">
      <xsl:apply-templates select="./*|./text()" mode="paragraph" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="h1|h2|h3|h4" mode="html">
    <xsl:element name="head">
      <xsl:attribute name="type">subtitle</xsl:attribute>
      <xsl:attribute name="subtype"><xsl:value-of select="local-name()"/></xsl:attribute>
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

  <xsl:template match="span[.//text()[string-length(normalize-space()) > 0 ] ]" mode="paragraph">
    <xsl:apply-templates select="*|text()" mode="paragraph" />
  </xsl:template>

  <xsl:template match="strong[.//text()[string-length(normalize-space()) > 0 ] ]" mode="paragraph">
    <xsl:text> </xsl:text>
    <xsl:element name="hi">
      <xsl:attribute name="rend">bold</xsl:attribute>
      <xsl:apply-templates select="*|text()" mode="paragraph" />
    </xsl:element>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="br" mode="paragraph">
    <xsl:choose>
      <xsl:when test="string-length(normalize-space(concat('','',./following-sibling::text()))) = 0">
        <xsl:message>removing newline at the end element <xsl:value-of select="./ancestor::p[1]/@xml:id" /></xsl:message>
        <!--<xsl:comment>REMOVING-BR</xsl:comment>-->
        <xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="lb"/><xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- TABLE -->
  <xsl:template match="table" mode="html">
    <xsl:message>TABLE </xsl:message>
    <xsl:element name="table">
      <xsl:apply-templates select="./caption" mode="paragraph" />
      <xsl:apply-templates select=".//tr" mode="html" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="tr" mode="html">
    <xsl:message>TABLE row </xsl:message>
    <xsl:element name="row">
      <xsl:apply-templates select="./*" mode="paragraph" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="caption" mode="paragraph">
    <xsl:message>TABLE head </xsl:message>
    <xsl:element name="head">
      <xsl:apply-templates select=".//text()" mode="paragraph" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="td|th" mode="paragraph">
    <xsl:message>TABLE cell </xsl:message>
    <xsl:element name="cell">
      <xsl:apply-templates select=".//text()" mode="paragraph" />
    </xsl:element>
  </xsl:template>


  <!-- LIST -->
  <xsl:template match="ul|ol" mode="html">
    <xsl:message>List </xsl:message>
    <xsl:element name="list">
      <xsl:apply-templates select="./li" mode="html" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="li[.//text()[string-length(normalize-space()) > 0 ] ]" mode="html">
    <xsl:element name="item">
      <xsl:apply-templates select="./*|./text()" mode="paragraph" />
    </xsl:element>
  </xsl:template>


  <!-- TO BE REMOVED -->
  <xsl:template match="*[contains(@class,'inline')]" mode="html">
    <xsl:message>removing inline</xsl:message>
  </xsl:template>
  <xsl:template match="*[contains(@class,'embed')]" mode="html">
    <xsl:message>removing embed</xsl:message>
  </xsl:template>

</xsl:stylesheet>