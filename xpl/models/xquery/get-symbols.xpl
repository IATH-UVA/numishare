<?xml version="1.0" encoding="UTF-8"?>
<!--
	Author: Ethan Gruber
	Last Modified: December 2019
	Function: Execute an XQuery to generate pages for symbols in the local Numishare instance.	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">
	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>
	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- get XQuery from disk -->
	<p:processor name="oxf:url-generator">
		<p:input name="config">
			<config>
				<url>oxf:/apps/numishare/ui/xquery/get-symbols.xquery</url>
				<content-type>text/plain</content-type>
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:output name="data" id="query"/>
	</p:processor>
	
	<p:processor name="oxf:text-converter">
		<p:input name="data" href="#query"/>
		<p:input name="config">
			<config/>
		</p:input>
		<p:output name="data" id="query-document"/>
	</p:processor>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="xquery" href="#query-document"/>
		<p:input name="data" href="../../../exist-config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:param name="page" select="doc('input:request')/request/parameters/parameter[name='page']/value"/>
					<xsl:param name="symbol" select="doc('input:request')/request/parameters/parameter[name='symbol']"/>
					
					<xsl:variable name="limit">24</xsl:variable>
					<xsl:variable name="offset">
						<xsl:choose>
							<xsl:when test="string-length($page) &gt; 0 and $page castable as xs:integer and number($page) > 0">
								<xsl:value-of select="(($page - 1) * number($limit)) + 1"/>
							</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:variable name="collection-name" select="substring-before(substring-after(doc('input:request')/request/request-uri, 'numishare/'), '/')"/>
					<xsl:variable name="pieces" select="tokenize(/exist-config/url, '/')"/>					
					<xsl:variable name="xquery" select="doc('input:xquery')"/>
					
					<config>
						<vendor>exist</vendor>
						<property>
							<name>serverName</name>
							<value>
								<xsl:value-of select="substring-before($pieces[3], ':')"/>
							</value>
						</property>
						<property>
							<name>port</name>
							<value>
								<xsl:value-of select="substring-after($pieces[3], ':')"/>
							</value>
						</property>
						<property>
							<name>user</name>
							<value>
								<xsl:value-of select="/exist-config/username"/>
							</value>
						</property>
						<property>
							<name>password</name>
							<value>
								<xsl:value-of select="/exist-config/password"/>
							</value>
						</property>
						<query>
							<xsl:choose>
								<xsl:when test="count($symbol//value) &gt; 0">
									<xsl:variable name="xpath">
										<xsl:text>[</xsl:text>
										<xsl:for-each select="$symbol//value">
											<xsl:value-of select="concat('descendant::crm:P106_is_composed_of = &#x022;', ., '&#x022;')"/>
											<xsl:if test="not(position() = last())">
												<xsl:text> and </xsl:text>
											</xsl:if>
										</xsl:for-each>
										<xsl:text>]</xsl:text>
									</xsl:variable>
									
									<xsl:value-of select="replace(replace(replace(replace($xquery, 'numishare', $collection-name), 'XPATH', $xpath), 'OFFSET', $offset), 'LIMIT', $limit)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="replace(replace(replace(replace($xquery, 'numishare', $collection-name), 'XPATH', ''), 'OFFSET', $offset), 'LIMIT', $limit)"/>
								</xsl:otherwise>
							</xsl:choose>
							
						</query>
					</config>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="xquery-config"/>
	</p:processor>

	<p:processor name="oxf:xquery">
		<p:input name="config" href="#xquery-config"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
