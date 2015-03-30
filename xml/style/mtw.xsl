<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:cvs="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.CVS"
                exclude-result-prefixes="cvs"
                version="1.0">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/html/docbook.xsl"/>
<xsl:include href="html-titlepage.xsl"/>

<xsl:param name="html.stylesheet">mtw.css</xsl:param>
<xsl:param name="output.media" select="'online'"/>

<xsl:param name="generate.toc">
/appendix nop
/article  nop
book      toc,figure,table,example,equation
/chapter  nop
part      toc
/preface  nop
qandadiv  nop
qandaset  nop
reference nop
/section  nop
set       nop
</xsl:param>

<xsl:template match="processing-instruction('lb')">
  <br/>
</xsl:template>

<xsl:template match="processing-instruction('lb')" mode="no.anchor.mode">
  <xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="para">
  <xsl:if test="not(@condition)
                or (@condition = $output.media)">
    <p>
      <xsl:if test="@role and $para.propagates.style != 0">
        <xsl:attribute name="class">
          <xsl:value-of select="@role"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test="position() = 1 and parent::listitem">
        <xsl:call-template name="anchor">
          <xsl:with-param name="node" select="parent::listitem"/>
        </xsl:call-template>
      </xsl:if>

      <xsl:call-template name="anchor"/>
      <xsl:apply-templates/>
    </p>
  </xsl:if>
</xsl:template>

<xsl:template match="footnote/para[1]">
  <xsl:apply-imports/>
</xsl:template>

<xsl:template match="phrase">
  <xsl:if test="not(@condition)
                or (@condition = $output.media)">
    <xsl:apply-imports/>
  </xsl:if>
</xsl:template>

<xsl:template match="ulink">
  <xsl:choose>
    <xsl:when test="not(@condition)
                    or (@condition = $output.media)">
      <xsl:apply-imports/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- ============================================================ -->

<xsl:template name="titlepage-block">
  <xsl:variable name="isbn" select="bookinfo/isbn[1]"/>
  <xsl:variable name="version" select="bookinfo/releaseinfo[1]"/>
  <xsl:variable name="date" select="bookinfo/pubdate[1]"/>
  <xsl:variable name="legalnotice" select="bookinfo/legalnotice[1]"/>
  <xsl:variable name="copyright" select="bookinfo/copyright[1]"/>

  <p class="titlepage-block">
    <span class="authorgroup">
      <xsl:call-template name="gentext">
        <xsl:with-param name="key">by</xsl:with-param>
      </xsl:call-template>
      <xsl:text>&#160;</xsl:text>
      <xsl:apply-templates select="bookinfo/author" mode="titleblock"/>
    </span>
    <br/>
    <span class="isbn">
      <xsl:text>ISBN: </xsl:text>
      <xsl:apply-templates select="$isbn/node()"/>
      <xsl:text> (out-of-print)</xsl:text>
    </span>
    <br/>
    <span class="version">
      <xsl:apply-templates select="$version/node()"/>
    </span>
    <br/>
    <span class="date">
      <!-- rcsdate = "$Date: 2002/08/23 15:03:24 $" -->
      <!-- timeString = "dow mon dd hh:mm:ss TZN yyyy" -->
      <xsl:variable name="timeString" select="cvs:localTime($date/text())"/>
      <xsl:text>Updated: </xsl:text>
      <xsl:value-of select="substring($timeString, 1, 3)"/>
      <xsl:text>, </xsl:text>
      <xsl:value-of select="substring($timeString, 9, 2)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="substring($timeString, 5, 3)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="substring($timeString, 25, 4)"/>
    </span>
  </p>
  <xsl:apply-templates select="$copyright" mode="titlepage.mode"/>
</xsl:template>

<xsl:template match="authorgroup/author" mode="titleblock">
  <xsl:if test="position() &gt; 1 and last() &gt; 2">,</xsl:if>
  <xsl:if test="position() &gt; 1 and position() = last()"> and</xsl:if>
  <xsl:if test="position() &gt; 1">&#160;</xsl:if>
  <xsl:apply-templates select="."/>
</xsl:template>

<xsl:template match="authorgroup/othercredit" mode="titleblock">
  <xsl:if test="position() &gt; 1 and last() &gt; 2">,</xsl:if>
  <xsl:if test="position() &gt; 1 and position() = last()"> and</xsl:if>
  <xsl:if test="position() &gt; 1"> </xsl:if>
  <xsl:apply-templates select="."/>
  <xsl:if test="contrib">
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="contrib" mode="titleblock"/>
    <xsl:text>)</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="othercredit/contrib" mode="titleblock">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="copyright" mode="titlepage.mode">
  <br clear="all"/>
  <xsl:apply-templates select="../legalnotice" mode="titlepage.mode"/>
</xsl:template>

</xsl:stylesheet>
