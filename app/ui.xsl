<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:local="local"
  exclude-result-prefixes="xs"
  extension-element-prefixes="ixsl">
  
  <xsl:output method="html"/>
  
  <xsl:template match="/">
    <xsl:result-document href="#debug">
      <xsl:if test="count(//page[@id='index']) = 0">
        <p>Write <code><![CDATA[<page id="index" label="Your title"/>]]></code>, please.</p>
      </xsl:if>
    </xsl:result-document>
    <xsl:result-document href="#baseset">
      <xsl:apply-templates select="//base"/>
    </xsl:result-document>
    <xsl:result-document href="#pageset">
        <xsl:apply-templates select="//page"/>
        <xsl:apply-templates select="//pageset" mode="allpages"/>
        <xsl:apply-templates select="//storyset"/>
    </xsl:result-document>
    <xsl:variable name="page-ref-tmp" select="substring-after(ixsl:get(ixsl:window(), 'location.href'), '#')"/>
    <xsl:variable name="page-ref" select="if ($page-ref-tmp = '') then 'index' else $page-ref-tmp"/>
    <xsl:call-template name="load-page">
      <xsl:with-param name="page-ref" select="$page-ref"/>
    </xsl:call-template>
    <xsl:if test="count(tokenize($page-ref-tmp, ':')) = 2">
      <xsl:sequence select="ixsl:eval('window.scrollTo(0, document.getElementById(decodeURIComponent(''' || $page-ref-tmp || ''')).offsetTop)')"/> <!-- To jump to story's anchor -->
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="." mode="ixsl:onhashchange"><!-- history back (or onclick) -->
    <xsl:call-template name="load-page">
      <xsl:with-param name="page-ref" select="substring-after(ixsl:get(ixsl:window(), 'location.href'), '#')"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="a" mode="ixsl:onclick">
    <!-- changing location.href triggers ixsl:onhashchange (and ixsl:onpopstate) -->
    <ixsl:set-property name="location.href" select="substring-before(ixsl:get(ixsl:window(), 'location.href'), '#') || @href"/>
  </xsl:template>
  
  <xsl:template name="merge">
    <xsl:param name="base"/>
    <xsl:param name="page"/>
    <xsl:apply-templates select="$base" mode="merge">
      <xsl:with-param name="page" select="$page"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="@* | node()" mode="merge">
    <xsl:param name="page"/>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="@class='center'">
          <xsl:apply-templates select="@* | node()" mode="merge"/>
          <xsl:copy-of select="$page"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@* | node()" mode="merge">
            <xsl:with-param name="page" select="$page"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="load-page">
    <xsl:param name="page-ref"/>
    <xsl:result-document href="#screen" method="ixsl:replace-content">
      <xsl:variable name="page-ref-tmp" select="substring-after(ixsl:get(ixsl:window(), 'location.href'), '#')"/>
      <xsl:choose>
        <!--<xsl:when test="$page-ref-tmp = ('_allpages', '_stories')">-->
        <xsl:when test="$page-ref-tmp = '_allpages'">
          <xsl:variable name="page" select="ixsl:page()//div[@id='pageset']//div[@id=$page-ref-tmp]"/>
          <xsl:copy-of select="$page"/>
        </xsl:when>
        <xsl:when test="starts-with($page-ref-tmp, '_stories')">
          <xsl:variable name="page" select="ixsl:page()//div[@id='pageset']//div[@id=tokenize($page-ref-tmp, ':')[1]]"/>
          <xsl:copy-of select="$page"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="page-ref" select="if ($page-ref-tmp = '') then 'index' else $page-ref-tmp"/>
          <xsl:variable name="page" select="ixsl:page()//div[@id='pageset']//div[@id=$page-ref]"/>
          <xsl:variable name="base-ref" select="(ixsl:source()//g[@base-ref][.//page[@id=$page-ref]]/@base-ref)[last()]"/>
          <xsl:variable name="base" select="(ixsl:page()//div[@id='baseset']//div[@id=$base-ref])[last()]"/>
          <xsl:choose>
            <xsl:when test="$base">
              <xsl:apply-templates select="$base" mode="merge">
                <xsl:with-param name="page" select="$page"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="$page"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="base">
    <div id="{@id}" class="base">
      <header><xsl:apply-templates select="head"/></header>
      <div class="middle">
        <div class="left"><xsl:apply-templates select="left"/></div>
        <div class="center"></div>
        <div class="right"><xsl:apply-templates select="right"/></div>
      </div>
      <footer><xsl:apply-templates select="foot"/></footer>
    </div>
  </xsl:template>
  
  <xsl:template match="pageset" mode="allpages">
    <div id="_allpages" class="page">
      <h2>All Pages</h2>
      <xsl:apply-templates mode="allpages"/>
    </div>
  </xsl:template>
  
  <xsl:template match="g" mode="allpages">
    <ul class="allpages">
      <li>
        {<xsl:value-of select="@base-ref"/>}
        "<xsl:value-of select="@note"/>"
        <xsl:apply-templates mode="allpages"/>
      </li>
    </ul>
  </xsl:template>
  
  <xsl:template match="page" mode="allpages">
    <ul>
      <li>
        [ <a href="#{@id}"><xsl:value-of select="@id"/></a>] <xsl:value-of select="@label"/>
      </li>
    </ul>
  </xsl:template>
  
  <xsl:template match="storyset">
    <div id="_stories" class="page">
      <h2>Stories</h2>
      <div class="story-tree">
        <xsl:apply-templates mode="story-tree"/>
      </div>
      <xsl:apply-templates mode="stories"/>
    </div>
  </xsl:template>
  
  <xsl:template match="g" mode="stories">
    <div class="g-story">
      <xsl:if test="@note">
        <h3><xsl:value-of select="@note"/></h3>
      </xsl:if>
      <xsl:apply-templates mode="stories"/>
    </div>
  </xsl:template>
  
  <xsl:template match="story" mode="stories">
    <div id="_stories:{@label}" class="story">
      <h4><xsl:value-of select="@label"/></h4>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="g" mode="story-tree">
    <ul>
      <li>
        <i><xsl:value-of select="@note"/></i>
        <ul>
          <xsl:apply-templates mode="story-tree"/>
        </ul>
      </li>
    </ul>
  </xsl:template>
  
  <xsl:template match="story" mode="story-tree">
    <li><a href="#_stories:{@label}"><xsl:value-of select="@label"/></a></li>
  </xsl:template>
  
  <xsl:template match="page">
    <div id="{@id}" class="page">
      <h2><xsl:value-of select="@label"/></h2>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="sect">
    <div class="sect">
      <xsl:if test="@label">
        <h3><xsl:value-of select="@label"/></h3>
      </xsl:if>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="linkset">
    <xsl:if test="@label">
      <p><xsl:value-of select="@label"/></p>
    </xsl:if>
    <ul>
      <xsl:apply-templates select="link" mode="linkset"/>
    </ul>
  </xsl:template>
  
  <xsl:template match="link" mode="linkset">
    <li>
      <xsl:apply-templates select="."/>
    </li>
  </xsl:template>
  
  <xsl:template match="link">
    <xsl:param name="class"/>
    <xsl:variable name="page-ref" select="@page-ref"/>
    <xsl:variable name="page" select="(ixsl:source()//page[@id=$page-ref])[1]"/>
    <a href="#{$page/@id}" onclick="javascript: return false;" class="{$class}">
      <xsl:choose>
        <xsl:when test="@label">
          <xsl:value-of select="@label"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$page/@label"/>
        </xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>
  
  <xsl:template match="form">
    <form>
      <xsl:apply-templates select="input"/>
      <xsl:apply-templates select="link">
        <xsl:with-param name="class" select="'button'"/>
      </xsl:apply-templates>
    </form>
  </xsl:template>
  
  <xsl:template match="input">
    <xsl:if test="@label">
      <label><xsl:value-of select="@label"/></label>
    </xsl:if>
    <input type="text"/><br/>
  </xsl:template>
  
  <xsl:template match="text">
    <p><xsl:value-of select="."/></p>
  </xsl:template>
  
  <xsl:template match="pict">
    <pre><xsl:value-of select="local:remove-indent(.)"/></pre>
  </xsl:template>
  
  <xsl:template match="grid">
    <xsl:variable name="grid" select="."/>
    <table border="1">
      <xsl:for-each select="1 to 3">
        <tr>
          <xsl:for-each select="1 to 3">
            <td><xsl:apply-templates select="$grid/*"/></td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>    
  </xsl:template>
  
  <xsl:template match="svg">
    <xsl:element name="{name()}" namespace="http://www.w3.org/2000/svg">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="svg"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="*" mode="svg">
    <xsl:element name="{name()}" namespace="http://www.w3.org/2000/svg">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="svg"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:function name="local:remove-indent">
    <xsl:param name="text"/>
    <xsl:variable name="indent-num" select="
      min(
        for $line in tokenize(replace($text, '^&#xa;', ''), '&#xa;')
        return
          if (matches($line, '^ +$')) then number('INF')
          else string-length($line) - string-length(replace($line, '^&#x20;+', ''))
      )
    "/>
    <xsl:value-of select="
      for $line in tokenize($text, '&#xa;')
      return concat(substring($line, $indent-num + 1, string-length($line)), '&#xa;')
    "/>
  </xsl:function>
  
</xsl:transform>