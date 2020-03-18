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

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="request" href="#request"/>
		<p:input name="data" href="../../../exist-config.xml"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<xsl:output indent="yes"/>
				<xsl:template match="/">
					<xsl:param name="symbol" select="doc('input:request')/request/parameters/parameter[name='symbol']"/>
					<xsl:variable name="collection-name" select="substring-before(substring-after(doc('input:request')/request/request-uri, 'numishare/'), '/')"/>
					<xsl:variable name="pieces" select="tokenize(/exist-config/url, '/')"/>

					<xsl:variable name="xquery">
						<![CDATA[xquery version "1.0"; 
						declare namespace crm = "http://www.cidoc-crm.org/cidoc-crm/";
						declare namespace nmo = "http://nomisma.org/ontology#";
						<count>
							{
							count(collection('/db/numishare/symbols')XPATH)
							}
						</count>]]>
					</xsl:variable>
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

									<xsl:value-of select="replace(replace($xquery, 'numishare', $collection-name), 'XPATH', $xpath)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="replace(replace($xquery, 'numishare', $collection-name), 'XPATH', '')"/>
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
