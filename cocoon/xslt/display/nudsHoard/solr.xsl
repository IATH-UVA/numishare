<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:nh="http://nomisma.org/nudsHoard" xmlns:nuds="http://nomisma.org/nuds" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:datetime="http://exslt.org/dates-and-times" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:exsl="http://exslt.org/common"
	xmlns:mets="http://www.loc.gov/METS/" xmlns:math="http://exslt.org/math" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:gml="http://www.opengis.net/gml/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" exclude-result-prefixes="#all">
	<xsl:output method="xml" encoding="UTF-8"/>

	<xsl:template name="nudsHoard">
		<xsl:apply-templates select="//nh:nudsHoard"/>
	</xsl:template>

	<xsl:template match="nh:nudsHoard">
		<xsl:variable name="all-dates">
			<dates>
				<xsl:for-each select="descendant::nuds:typeDesc">
					<xsl:choose>
						<xsl:when test="string(@xlink:href)">
							<xsl:variable name="href" select="@xlink:href"/>
							<xsl:for-each select="exsl:node-set($nudsGroup)//object[@xlink:href=$href]/descendant::*/@standardDate">
								<xsl:if test="number(.)">
									<date>
										<xsl:value-of select="number(.)"/>
									</date>
								</xsl:if>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="descendant::*/@standardDate">
								<xsl:if test="number(.)">
									<date>
										<xsl:value-of select="number(.)"/>
									</date>
								</xsl:if>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</dates>
		</xsl:variable>
		<xsl:variable name="dates">
			<dates>
				<xsl:for-each select="distinct-values(exsl:node-set($all-dates)//date)">
					<xsl:sort data-type="number"/>
					<date>
						<xsl:value-of select="number(.)"/>
					</date>
				</xsl:for-each>
			</dates>
		</xsl:variable>


		<doc>
			<field name="id">
				<xsl:value-of select="nh:nudsHeader/nh:nudsid"/>
			</field>
			<field name="collection-name">
				<xsl:value-of select="$collection-name"/>
			</field>
			<field name="title_display">
				<xsl:value-of select="nh:nudsHeader/nh:nudsid"/>
			</field>
			<field name="recordType">hoard</field>
			<field name="publisher_display">
				<xsl:value-of select="$publisher"/>
			</field>
			<field name="hasContents">
				<xsl:choose>
					<xsl:when test="count(nh:descMeta/nh:contentsDesc/nh:contents/*) &gt; 0">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</field>
			<field name="closing_date_display">
				<xsl:choose>
					<xsl:when test="count(exsl:node-set($dates)/dates/date) &gt; 0">
						<xsl:call-template name="nh:normalize_date">
							<xsl:with-param name="start_date" select="exsl:node-set($dates)/dates/date[last()]"/>
							<xsl:with-param name="end_date" select="exsl:node-set($dates)/dates/date[last()]"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>Unknown</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</field>
			<xsl:if test="count(exsl:node-set($dates)/dates/date) &gt; 0">
				<field name="tpq_num">
					<xsl:value-of select="exsl:node-set($dates)/dates/date[1]"/>
				</field>
				<field name="taq_num">
					<xsl:value-of select="exsl:node-set($dates)/dates/date[last()]"/>
				</field>
			</xsl:if>
			<field name="timestamp">
				<xsl:value-of select="if(contains(datetime:dateTime(), 'Z')) then datetime:dateTime() else concat(datetime:dateTime(), 'Z')"/>
			</field>

			<xsl:apply-templates select="nh:descMeta"/>

			<!-- apply templates for those typeDescs contained explicitly within the hoard -->
			<xsl:for-each select="descendant::nuds:typeDesc">
				<xsl:choose>
					<xsl:when test="string(@xlink:href)">
						<xsl:variable name="href" select="@xlink:href"/>
						<xsl:apply-templates select="exsl:node-set($nudsGroup)//object[@xlink:href=$href]/descendant::nuds:typeDesc">
							<xsl:with-param name="recordType">hoard</xsl:with-param>
						</xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select=".">
							<xsl:with-param name="recordType">hoard</xsl:with-param>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>

			<!-- insert coin type facets and URIs -->
			<xsl:for-each select="descendant::nuds:typeDesc[string(@xlink:href)]">
				<xsl:variable name="href" select="@xlink:href"/>
				<field name="coinType_uri">
					<xsl:value-of select="$href"/>
				</field>
				<field name="coinType_facet">
					<xsl:value-of select="exsl:node-set($nudsGroup)//object[@xlink:href=$href]/descendant::nuds:title"/>
				</field>
			</xsl:for-each>

			<!-- get sortable fields: distinct values in $nudsGroup -->
			<xsl:call-template name="get_hoard_sort_fields"/>
		</doc>
	</xsl:template>

	<xsl:template match="nh:descMeta">
		<xsl:apply-templates select="nh:hoardDesc"/>
		<xsl:apply-templates select="nh:refDesc"/>
		<!--<xsl:apply-templates select="nh:contentsDesc"/>-->
	</xsl:template>

	<xsl:template match="nh:hoardDesc">
		<xsl:apply-templates select="nh:findspot/nh:geogname[@xlink:role='findspot']"/>
	</xsl:template>

	<xsl:template name="nh:normalize_date">
		<xsl:param name="start_date"/>
		<xsl:param name="end_date"/>

		<xsl:choose>
			<xsl:when test="number($start_date) = number($end_date)">
				<xsl:if test="number($start_date) &lt; 500 and number($start_date) &gt; 0">
					<xsl:text>A.D. </xsl:text>
				</xsl:if>
				<xsl:value-of select="abs(number($start_date))"/>
				<xsl:if test="number($start_date) &lt; 0">
					<xsl:text> B.C.</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<!-- start date -->

				<xsl:if test="number($start_date) &lt; 500 and number($start_date) &gt; 0">
					<xsl:text>A.D. </xsl:text>
				</xsl:if>
				<xsl:value-of select="abs(number($start_date))"/>
				<xsl:if test="number($start_date) &lt; 0">
					<xsl:text> B.C.</xsl:text>
				</xsl:if>
				<xsl:text> - </xsl:text>

				<!-- end date -->
				<xsl:if test="number($end_date) &lt; 500 and number($end_date) &gt; 0">
					<xsl:text>A.D. </xsl:text>
				</xsl:if>
				<xsl:value-of select="abs(number($end_date))"/>
				<xsl:if test="number($end_date) &lt; 0">
					<xsl:text> B.C.</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--<xsl:template match="nh:contentsDesc">
		<xsl:apply-templates select="descendant::nuds:typeDesc"/>
	</xsl:template>-->
</xsl:stylesheet>