<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs nuds nh xlink mets numishare"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:nm="http://nomisma.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:nuds="http://nomisma.org/nuds" xmlns:nh="http://nomisma.org/nudsHoard" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:georss="http://www.georss.org/georss" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:oa="http://www.w3.org/ns/oa#" xmlns:owl="http://www.w3.org/2002/07/owl#"
	xmlns:pelagios="http://pelagios.github.io/vocab/terms#" xmlns:relations="http://pelagios.github.io/vocab/relations#" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:mets="http://www.loc.gov/METS/" xmlns:numishare="https://github.com/ewg118/numishare" version="2.0">

	<!-- ************** OBJECT-TO-RDF **************** -->
	<xsl:template name="rdf">
		<rdf:RDF>
			<xsl:choose>
				<xsl:when test="$mode='pelagios'">
					<xsl:choose>
						<xsl:when test="count(/content/*[local-name()='nuds']) &gt; 0">
							<xsl:apply-templates select="/content/nuds:nuds" mode="pelagios"/>
						</xsl:when>
						<xsl:when test="count(/content/*[local-name()='nudsHoard']) &gt; 0">
							<xsl:apply-templates select="/content/nh:nudsHoard" mode="pelagios"/>
						</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$mode='nomisma'">
					<xsl:choose>
						<xsl:when test="count(/content/*[local-name()='nuds']) &gt; 0">
							<xsl:apply-templates select="/content/nuds:nuds" mode="nomisma"/>
						</xsl:when>
						<xsl:when test="count(/content/*[local-name()='nudsHoard']) &gt; 0">
							<xsl:apply-templates select="/content/nh:nudsHoard" mode="nomisma"/>
						</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$mode='cidoc'">
					<xsl:choose>
						<xsl:when test="count(/content/*[local-name()='nuds']) &gt; 0">
							<xsl:apply-templates select="/content/nuds:nuds" mode="cidoc"/>
						</xsl:when>
						<xsl:when test="count(/content/*[local-name()='nudsHoard']) &gt; 0">
							<xsl:apply-templates select="/content/nh:nudsHoard" mode="cidoc"/>
						</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="count(/content/*[local-name()='nuds']) &gt; 0">
							<xsl:apply-templates select="/content/nuds:nuds" mode="nomisma"/>
						</xsl:when>
						<xsl:when test="count(/content/*[local-name()='nudsHoard']) &gt; 0">
							<xsl:apply-templates select="/content/nh:nudsHoard" mode="nomisma"/>
						</xsl:when>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="nuds:nuds|nh:nudsHoard" mode="pelagios">
		<xsl:variable name="id" select="descendant::*[local-name()='recordId']"/>
		<!-- get timestamp of last modification date of the NUDS record -->
		<xsl:variable name="date" select="descendant::*:maintenanceEvent[last()]/*:eventDateTime/@standardDateTime"/>

		<foaf:Organization rdf:about="{$url}pelagios.rdf#agents/me">
			<foaf:name>
				<xsl:value-of select="//config/template/agencyName"/>
			</foaf:name>
		</foaf:Organization>

		<pelagios:AnnotatedThing rdf:about="{$url}pelagios.rdf#{$id}">
			<xsl:for-each select="descendant::*:descMeta/*:title">
				<dcterms:title>
					<xsl:if test="@xml:lang">
						<xsl:attribute name="xml:lang" select="@xml:lang"/>
					</xsl:if>
					<xsl:value-of select="."/>
				</dcterms:title>				
			</xsl:for-each>
			<foaf:homepage rdf:resource="{$url}id/{$id}"/>
			<xsl:if test="string(@recordType)">
				<!-- dates -->
				<xsl:choose>
					<xsl:when test="$nudsGroup//nuds:typeDesc/nuds:date">
						<dcterms:temporal>start=<xsl:value-of select="numishare:iso-to-digit($nudsGroup//nuds:typeDesc/nuds:date/@standardDate)"/>; end=<xsl:value-of
								select="numishare:iso-to-digit($nudsGroup//nuds:typeDesc/nuds:date/@standardDate)"/></dcterms:temporal>
					</xsl:when>
					<xsl:when test="$nudsGroup//nuds:typeDesc/nuds:dateRange">
						<dcterms:temporal>start=<xsl:value-of select="numishare:iso-to-digit($nudsGroup//nuds:typeDesc/nuds:dateRange/nuds:fromDate/@standardDate)"/>; end=<xsl:value-of
								select="numishare:iso-to-digit($nudsGroup//nuds:typeDesc/nuds:dateRange/nuds:toDate/@standardDate)"/></dcterms:temporal>
					</xsl:when>
				</xsl:choose>

				<xsl:if test="@recordType='physical'">
					<!-- images -->
					<xsl:apply-templates select="nuds:digRep/mets:fileSec" mode="pelagios"/>
				</xsl:if>
			</xsl:if>
		</pelagios:AnnotatedThing>

		<!-- create annotations from pleiades URIs found in nomisma RDF and from findspots -->
		<xsl:for-each select="distinct-values($rdf//skos:related[contains(@rdf:resource, 'pleiades')]/@rdf:resource)">
			<oa:Annotation rdf:about="{$url}pelagios.rdf#{$id}/annotations/{format-number(position(), '000')}">
				<oa:hasBody rdf:resource="{.}#this"/>
				<oa:hasTarget rdf:resource="{$url}pelagios.rdf#{$id}"/>
				<pelagios:relation rdf:resource="http://pelagios.github.io/vocab/relations#attestsTo"/>
				<oa:annotatedBy rdf:resource="{$url}pelagios.rdf#agents/me"/>
				<oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
					<xsl:value-of select="$date"/>
				</oa:annotatedAt>
			</oa:Annotation>
		</xsl:for-each>

		<xsl:apply-templates select="descendant::*:geogname[@xlink:role='findspot'][string(@xlink:href)]|descendant::*:findspotDesc[string(@xlink:href)]" mode="pelagios">
			<xsl:with-param name="id" select="$id"/>
			<xsl:with-param name="count" select="count(distinct-values($rdf//skos:related[contains(@rdf:resource, 'pleiades')]/@rdf:resource))"/>
			<xsl:param name="date" select="$date"/>
		</xsl:apply-templates>

	</xsl:template>

	<xsl:template match="nuds:nuds|nh:nudsHoard" mode="cidoc">
		<xsl:variable name="id" select="descendant::*[local-name()='recordId']"/>

		<xsl:text>(not yet developed)</xsl:text>
	</xsl:template>

	<!-- PROCESS NUDS RECORDS INTO NOMISMA/METIS COMPLIANT RDF MODELS -->
	<xsl:template match="nuds:nuds" mode="nomisma">
		<xsl:variable name="id" select="descendant::*[local-name()='recordId']"/>

		<xsl:choose>
			<xsl:when test="@recordType='conceptual'">
				<nm:type_series_item rdf:about="{$url}id/{$id}">
					<!-- insert titles -->
					<xsl:for-each select="descendant::nuds:descMeta/nuds:title">
						<skos:prefLabel>
							<xsl:if test="string(@xml:lang)">
								<xsl:attribute name="xml:lang" select="@xml:lang"/>
							</xsl:if>
							<xsl:value-of select="."/>
						</skos:prefLabel>
						<skos:definition>
							<xsl:if test="string(@xml:lang)">
								<xsl:attribute name="xml:lang" select="@xml:lang"/>
							</xsl:if>
							<xsl:value-of select="."/>
						</skos:definition>
					</xsl:for-each>

					<!-- other ids -->
					<xsl:for-each select="descendant::*:otherRecordId[string(@semantic)]">
						<xsl:variable name="uri" select="if (contains(., 'http://')) then . else concat($url, 'id/', .)"/>
						<xsl:variable name="prefix" select="substring-before(@semantic, ':')"/>
						<xsl:variable name="namespace" select="ancestor::*:control/*:semanticDeclaration[*:prefix=$prefix]/*:namespace"/>
						<xsl:element name="{@semantic}" namespace="{$namespace}">
							<xsl:attribute name="rdf:resource" select="$uri"/>
						</xsl:element>
					</xsl:for-each>

					<!-- process typeDesc -->
					<xsl:apply-templates select="nuds:descMeta/nuds:typeDesc" mode="nomisma"/>
				</nm:type_series_item>
			</xsl:when>
			<xsl:when test="@recordType='physical'">
				<nm:coin rdf:about="{$url}id/{$id}">
					<dcterms:title>
						<xsl:if test="string(@xml:lang)">
							<xsl:attribute name="xml:lang" select="@xml:lang"/>
						</xsl:if>
						<xsl:value-of select="nuds:descMeta/nuds:title"/>
					</dcterms:title>
					<xsl:if test="nuds:descMeta/nuds:adminDesc/nuds:identifier">
						<dcterms:identifier>
							<xsl:value-of select="nuds:descMeta/nuds:adminDesc/nuds:identifier"/>
						</dcterms:identifier>
					</xsl:if>
					<xsl:if test="nuds:control/nuds:maintenanceAgency/nuds:agencyName">
						<dcterms:publisher>
							<xsl:value-of select="nuds:control/nuds:maintenanceAgency/nuds:agencyName"/>
						</dcterms:publisher>
					</xsl:if>
					<xsl:for-each select="descendant::nuds:collection">
						<nm:collection>
							<xsl:choose>
								<xsl:when test="string(@xlink:href)">
									<xsl:attribute name="rdf:resource" select="@xlink:href"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="."/>
								</xsl:otherwise>
							</xsl:choose>
						</nm:collection>
					</xsl:for-each>
					<xsl:if test="string(nuds:descMeta/nuds:typeDesc/@xlink:href)">
						<nm:type_series_item rdf:resource="{nuds:descMeta/nuds:typeDesc/@xlink:href}"/>
					</xsl:if>

					<!-- other ids -->
					<xsl:for-each select="descendant::*:otherRecordId[string(@semantic)]">
						<xsl:variable name="uri" select="if (contains(., 'http://')) then . else concat($url, 'id/', .)"/>
						<xsl:variable name="prefix" select="substring-before(@semantic, ':')"/>
						<xsl:variable name="namespace" select="ancestor::*:control/*:semanticDeclaration[*:prefix=$prefix]/*:namespace"/>
						<xsl:element name="{@semantic}" namespace="{$namespace}">
							<xsl:attribute name="rdf:resource" select="$uri"/>
						</xsl:element>
					</xsl:for-each>

					<!-- physical attributes -->
					<xsl:apply-templates select="nuds:descMeta/nuds:physDesc" mode="nomisma"/>

					<!-- findspot-->
					<xsl:apply-templates select="nuds:descMeta/nuds:findspotDesc" mode="nomisma"/>

					<!-- images -->
					<xsl:apply-templates select="nuds:digRep/mets:fileSec" mode="nomisma"/>
				</nm:coin>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mets:fileSec" mode="nomisma">
		<xsl:for-each select="mets:fileGrp">
			<xsl:variable name="side" select="@USE"/>

			<xsl:element name="nm:{$side}">
				<rdf:Description>
					<xsl:for-each select="mets:file">
						<xsl:choose>
							<xsl:when test="@USE='thumbnail'">
								<foaf:thumbnail>
									<xsl:attribute name="rdf:resource">
										<xsl:choose>
											<xsl:when test="contains(mets:FLocat/@xlink:href, 'http://')">
												<xsl:value-of select="mets:FLocat/@xlink:href"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat($url, mets:FLocat/@xlink:href)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
								</foaf:thumbnail>
							</xsl:when>
							<xsl:when test="@USE='reference'">
								<foaf:depiction>
									<xsl:attribute name="rdf:resource">
										<xsl:choose>
											<xsl:when test="contains(mets:FLocat/@xlink:href, 'http://')">
												<xsl:value-of select="mets:FLocat/@xlink:href"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat($url, mets:FLocat/@xlink:href)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
								</foaf:depiction>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
				</rdf:Description>				
			</xsl:element>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:physDesc" mode="nomisma">
		<xsl:if test="nuds:axis">
			<nm:axis rdf:datatype="xs:integer">
				<xsl:value-of select="nuds:axis"/>
			</nm:axis>
		</xsl:if>

		<xsl:for-each select="nuds:measurementsSet/*">
			<xsl:element name="nm:{local-name()}">
				<xsl:attribute name="rdf:datatype">xs:decimal</xsl:attribute>
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:typeDesc" mode="nomisma">
		<xsl:if test="nuds:objectType[@xlink:href]">
			<nm:object_type rdf:resource="{nuds:objectType/@xlink:href}"/>
		</xsl:if>

		<xsl:if test="nuds:obverse">
			<nm:obverse>
				<rdf:Description>
					<xsl:apply-templates select="nuds:obverse" mode="nomisma"/>
				</rdf:Description>
			</nm:obverse>
		</xsl:if>
		<xsl:if test="nuds:reverse">
			<nm:obverse>
				<rdf:Description>
					<xsl:apply-templates select="nuds:reverse" mode="nomisma"/>
				</rdf:Description>
			</nm:obverse>
		</xsl:if>

		<xsl:apply-templates select="nuds:material|nuds:denomination|nuds:manufacture" mode="nomisma"/>
		<xsl:apply-templates select="descendant::nuds:geogname|descendant::nuds:persname|descendant::nuds:corpname" mode="nomisma"/>
		<xsl:apply-templates select="nuds:date[@standardDate]|nuds:dateRange[child::node()/@standardDate]" mode="nomisma"/>
	</xsl:template>

	<xsl:template match="nuds:obverse|nuds:reverse" mode="nomisma">
		<xsl:if test="nuds:legend">
			<nm:legend>
				<xsl:if test="string(@xml:lang)">
					<xsl:attribute name="xml:lang" select="@xml:lang"/>
				</xsl:if>
				<xsl:value-of select="nuds:legend"/>
			</nm:legend>
		</xsl:if>
		<xsl:for-each select="nuds:type/nuds:description">
			<nm:description>
				<xsl:if test="string(@xml:lang)">
					<xsl:attribute name="xml:lang" select="@xml:lang"/>
				</xsl:if>
				<xsl:value-of select="."/>
			</nm:description>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:material|nuds:denomination|nuds:manufacture|nuds:geogname|nuds:persname|nuds:corpname" mode="nomisma">
		<xsl:variable name="element" select="if (@xlink:role) then @xlink:role else local-name()"/>

		<xsl:choose>
			<xsl:when test="string(@xlink:href)">
				<xsl:element name="nm:{$element}">
					<xsl:attribute name="rdf:resource" select="@xlink:href"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="nm:{$element}">
					<xsl:value-of select="."/>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="nuds:date" mode="nomisma">
		<nm:start_date rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">
			<xsl:value-of select="@standardDate"/>
		</nm:start_date>
		<nm:end_date rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">
			<xsl:value-of select="@standardDate"/>
		</nm:end_date>

	</xsl:template>

	<xsl:template match="nuds:dateRange" mode="nomisma">
		<nm:start_date rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">
			<xsl:value-of select="nuds:fromDate/@standardDate"/>
		</nm:start_date>
		<nm:end_date rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">
			<xsl:value-of select="nuds:toDate/@standardDate"/>
		</nm:end_date>
	</xsl:template>

	<xsl:template match="nuds:findspotDesc" mode="nomisma">
		<xsl:if test="string(@xlink:href)">
			<nm:findspot rdf:resource="{@xlink:href}"/>
		</xsl:if>
	</xsl:template>

	<!-- PROCESS NUDS-HOARD RECORDS INTO NOMISMA/METIS COMPLIANT RDF MODELS -->
	<xsl:template match="nh:nudsHoard" mode="nomisma">
		<xsl:variable name="id" select="descendant::*[local-name()='recordId']"/>

		<nm:hoard rdf:about="{$url}id/{$id}">
			<xsl:choose>
				<xsl:when test="lang('en', descendant::nh:descMeta/nh:title)">
					<dcterms:title xml:lang="en">
						<xsl:value-of select="descendant::nh:descMeta/nh:title[@xml:lang='en']"/>
					</dcterms:title>
				</xsl:when>
				<xsl:otherwise>
					<dcterms:title xml:lang="en">
						<xsl:value-of select="descendant::nh:descMeta/nh:title[1]"/>
					</dcterms:title>
				</xsl:otherwise>
			</xsl:choose>
			<dcterms:publisher>
				<xsl:value-of select="descendant::nh:control/nh:maintenanceAgency/nh:agencyName"/>
			</dcterms:publisher>
			<!-- other ids -->
			<xsl:for-each select="descendant::*:otherRecordId[string(@semantic)]">
				<xsl:variable name="uri" select="if (contains(., 'http://')) then . else concat($url, 'id/', .)"/>
				<xsl:variable name="prefix" select="substring-before(@semantic, ':')"/>
				<xsl:variable name="namespace" select="ancestor::*:control/*:semanticDeclaration[*:prefix=$prefix]/*:namespace"/>
				<xsl:element name="{@semantic}" namespace="{$namespace}">
					<xsl:attribute name="rdf:resource" select="$uri"/>
				</xsl:element>
			</xsl:for-each>
			<xsl:for-each select="descendant::nh:geogname[@xlink:role='findspot'][string(@xlink:href)]">
				<xsl:variable name="href" select="@xlink:href"/>
				<nm:findspot>
					<rdf:Description rdf:about="{@xlink:href}">
						<xsl:if test="contains(@xlink:href, 'geonames.org')">
							<xsl:variable name="geonames-url">
								<xsl:text>http://api.geonames.org</xsl:text>
							</xsl:variable>
							<xsl:variable name="geonames_api_key" select="/content/config/geonames_api_key"/>

							<xsl:variable name="geonameId" select="tokenize($href, '/')[4]"/>
							<xsl:variable name="geonames_data" as="element()*">
								<xml>
									<xsl:copy-of select="document(concat($geonames-url, '/get?geonameId=', $geonameId, '&amp;username=', $geonames_api_key, '&amp;style=full'))"/>
								</xml>
							</xsl:variable>

							<geo:lat>
								<xsl:value-of select="$geonames_data//lat"/>
							</geo:lat>
							<geo:long>
								<xsl:value-of select="$geonames_data//lng"/>
							</geo:long>
						</xsl:if>
					</rdf:Description>

				</nm:findspot>
			</xsl:for-each>
			<!-- closing date -->
			<xsl:choose>
				<xsl:when test="not(descendant::nh:deposit/nh:date) and not(descendant::nh:deposit/nh:dateRange)">
					<xsl:variable name="nudsGroup" as="element()*">
						<nudsGroup>
							<xsl:variable name="type_series" as="element()*">
								<list>
									<xsl:for-each select="distinct-values(descendant::nuds:typeDesc[string(@xlink:href)]/substring-before(@xlink:href, 'id/'))">
										<type_series>
											<xsl:value-of select="."/>
										</type_series>
									</xsl:for-each>
								</list>
							</xsl:variable>
							<xsl:variable name="type_list" as="element()*">
								<list>
									<xsl:for-each select="distinct-values(descendant::nuds:typeDesc[string(@xlink:href)]/@xlink:href)">
										<type_series_item>
											<xsl:value-of select="."/>
										</type_series_item>
									</xsl:for-each>
								</list>
							</xsl:variable>
							
							<xsl:for-each select="$type_series//type_series">
								<xsl:variable name="type_series_uri" select="."/>
								
								<xsl:variable name="id-param">
									<xsl:for-each select="$type_list//type_series_item[contains(., $type_series_uri)]">
										<xsl:value-of select="substring-after(., 'id/')"/>
										<xsl:if test="not(position()=last())">
											<xsl:text>|</xsl:text>
										</xsl:if>
									</xsl:for-each>
								</xsl:variable>
								
								<xsl:if test="string-length($id-param) &gt; 0">
									<xsl:for-each select="document(concat($type_series_uri, 'apis/getNuds?identifiers=', encode-for-uri($id-param)))//nuds:nuds">
										<object xlink:href="{$type_series_uri}id/{nuds:control/nuds:recordId}">
											<xsl:copy-of select="."/>
										</object>
									</xsl:for-each>
								</xsl:if>
							</xsl:for-each>
							<xsl:for-each select="descendant::nuds:typeDesc[not(string(@xlink:href))]">
								<object>
									<xsl:copy-of select="."/>
								</object>
							</xsl:for-each>
						</nudsGroup>
					</xsl:variable>

					<!-- get date values for closing date -->
					<xsl:variable name="dates" as="element()*">
						<dates>
							<xsl:for-each select="distinct-values($nudsGroup/descendant::nuds:typeDesc/descendant::*/@standardDate)">
								<xsl:sort data-type="number"/>
								<xsl:if test="number(.)">
									<date>
										<xsl:value-of select="number(.)"/>
									</date>
								</xsl:if>
							</xsl:for-each>
						</dates>
					</xsl:variable>
					<xsl:if test="count($dates//date) &gt; 0">
						<nm:closing_date rdf:datatype="xs:gYear">
							<xsl:value-of select="format-number($dates//date[last()], '0000')"/>
						</nm:closing_date>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise> </xsl:otherwise>
			</xsl:choose>


			<xsl:for-each select="descendant::nuds:typeDesc/@xlink:href|descendant::nuds:undertypeDesc/@xlink:href">
				<nm:type_series_item rdf:resource="{.}"/>
			</xsl:for-each>
		</nm:hoard>
	</xsl:template>

	<!-- *************** PELAGIOS OBJECT TEMPLATES ************** -->
	<xsl:template match="mets:fileSec" mode="pelagios">
		<xsl:for-each select="mets:fileGrp">
			<xsl:variable name="side" select="@USE"/>

			<xsl:for-each select="mets:file">
				<xsl:choose>
					<xsl:when test="@USE='thumbnail'">
						<foaf:thumbnail>
							<xsl:attribute name="rdf:resource">
								<xsl:choose>
									<xsl:when test="contains(mets:FLocat/@xlink:href, 'http://')">
										<xsl:value-of select="mets:FLocat/@xlink:href"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($url, mets:FLocat/@xlink:href)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
						</foaf:thumbnail>
					</xsl:when>
					<xsl:when test="@USE='reference'">
						<foaf:depiction>
							<xsl:attribute name="rdf:resource">
								<xsl:choose>
									<xsl:when test="contains(mets:FLocat/@xlink:href, 'http://')">
										<xsl:value-of select="mets:FLocat/@xlink:href"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($url, mets:FLocat/@xlink:href)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
						</foaf:depiction>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="*:geogname[@xlink:role='findspot']|*:findspotDesc" mode="pelagios">
		<xsl:param name="id"/>
		<xsl:param name="count"/>
		<xsl:param name="date"/>

		<oa:Annotation rdf:about="{$url}pelagios.rdf#{$id}/annotations/{format-number($count + 1, '000')}">
			<oa:hasBody rdf:resource="{@xlink:href}"/>
			<oa:hasTarget rdf:resource="{$url}pelagios.rdf#{$id}"/>
			<pelagios:relation rdf:resource="http://pelagios.github.io/vocab/relations#foundAt"/>
			<oa:annotatedBy rdf:resource="{$url}pelagios.rdf#agents/me"/>
			<oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
				<xsl:value-of select="$date"/>
			</oa:annotatedAt>
		</oa:Annotation>
	</xsl:template>

	<!-- ************** SOLR-TO-XML **************** -->
	<xsl:template name="atom">
		<xsl:param name="section"/>
		<xsl:variable name="path">
			<xsl:choose>
				<xsl:when test="$section='api'">
					<xsl:text>apis/search</xsl:text>
				</xsl:when>
				<xsl:when test="$section='feed'">
					<xsl:text>feed/</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="numFound">
			<xsl:value-of select="number(//result[@name='response']/@numFound)"/>
		</xsl:variable>
		<xsl:variable name="last" select="number($numFound - ($numFound mod 100))"/>
		<xsl:variable name="next" select="$start_var + 100"/>

		<!-- create sort parameter if there is string($sort) -->
		<xsl:variable name="sortParam">
			<xsl:if test="string($sort)">
				<xsl:text>&amp;sort=</xsl:text>
				<xsl:value-of select="$sort"/>
			</xsl:if>
		</xsl:variable>

		<feed xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
			xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns="http://www.w3.org/2005/Atom">
			<title>
				<xsl:value-of select="/content/config/title"/>
			</title>
			<id>
				<xsl:value-of select="$url"/>
			</id>
			<link rel="self" type="application/atom+xml" href="{$url}{$path}?q={$q}&amp;start={$start_var}{$sortParam}"/>
			<link rel="alternative" type="text/html" href="{$url}results?q={$q}&amp;start={$start_var}{$sortParam}"/>
			<xsl:if test="$next != $last">
				<link rel="next" type="application/atom+xml" href="{$url}{$path}?q={$q}&amp;start={$next}{$sortParam}"/>
			</xsl:if>
			<link rel="last" type="application/atom+xml" href="{$url}{$path}?q={$q}&amp;start={$last}{$sortParam}"/>
			<link rel="search" type="application/opensearchdescription+xml" href="{$url}opensearch.xml"/>
			<author>
				<name>
					<xsl:value-of select="//config/templates/agencyName"/>
				</name>
			</author>
			<!-- opensearch results -->
			<opensearch:totalResults>
				<xsl:value-of select="$numFound"/>
			</opensearch:totalResults>
			<opensearch:startIndex>
				<xsl:value-of select="$start_var"/>
			</opensearch:startIndex>
			<opensearch:itemsPerPage>
				<xsl:value-of select="$rows"/>
			</opensearch:itemsPerPage>
			<opensearch:Query role="request" searchTerms="{$q}" startPage="{$start_var}"/>

			<xsl:apply-templates select="descendant::doc" mode="atom"/>
		</feed>
	</xsl:template>

	<xsl:template name="rss">
		<xsl:param name="section"/>
		<xsl:variable name="path">
			<xsl:choose>
				<xsl:when test="$section='api'">
					<xsl:text>apis/search</xsl:text>
				</xsl:when>
				<xsl:when test="$section='feed'">
					<xsl:text>feed/</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="numFound">
			<xsl:value-of select="number(//result[@name='response']/@numFound)"/>
		</xsl:variable>
		<xsl:variable name="last" select="number($numFound - ($numFound mod 100))"/>
		<xsl:variable name="next" select="$start_var + 100"/>

		<!-- create sort parameter if there is string($sort) -->
		<xsl:variable name="sortParam">
			<xsl:if test="string($sort)">
				<xsl:text>&amp;sort=</xsl:text>
				<xsl:value-of select="$sort"/>
			</xsl:if>
		</xsl:variable>

		<rss version="2.0" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:atom="http://www.w3.org/2005/Atom">
			<channel>
				<title>
					<xsl:value-of select="/content/config/title"/>
				</title>
				<description>Numishare Collection</description>
				<link>
					<xsl:value-of select="$url"/>
				</link>
				<xsl:if test="string(/content/config/template/copyrightHolder) or string(/content/config/template/license)">
					<copyright>
						<xsl:if test="string(/content/config/template/copyrightHolder)">Copyright: <xsl:value-of select="/content/config/template/copyrightHolder"/></xsl:if>
						<xsl:if test="string(/content/config/template/copyrightHolder) and string(/content/config/template/license)">
							<xsl:text>, </xsl:text>
						</xsl:if>
						<xsl:if test="string(/content/config/template/license)">License: <xsl:value-of select="/content/config/template/license"/></xsl:if>
					</copyright>
				</xsl:if>
				<atom:link rel="self" type="application/atom+xml" href="{$url}{$path}?q={$q}&amp;start={$start_var}{$sortParam}"/>
				<atom:link rel="alternative" type="text/html" href="{$url}results?q={$q}&amp;start={$start_var}{$sortParam}"/>
				<xsl:if test="$next != $last">
					<atom:link rel="next" type="application/atom+xml" href="{$url}{$path}?q={$q}&amp;start={$next}{$sortParam}"/>
				</xsl:if>
				<atom:link rel="last" type="application/atom+xml" href="{$url}{$path}?q={$q}&amp;start={$last}{$sortParam}"/>
				<atom:link rel="search" type="application/opensearchdescription+xml" href="{$url}opensearch.xml"/>
				<!-- opensearch results -->
				<opensearch:totalResults>
					<xsl:value-of select="$numFound"/>
				</opensearch:totalResults>
				<opensearch:startIndex>
					<xsl:value-of select="$start_var"/>
				</opensearch:startIndex>
				<opensearch:itemsPerPage>
					<xsl:value-of select="$rows"/>
				</opensearch:itemsPerPage>
				<opensearch:Query role="request" searchTerms="{$q}" startPage="{$start_var}"/>

				<xsl:apply-templates select="descendant::doc" mode="rss"/>
			</channel>
		</rss>
	</xsl:template>

	<xsl:template match="doc" mode="atom">
		<entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:georss="http://www.georss.org/georss" xmlns:gx="http://www.google.com/kml/ext/2.2">
			<title>
				<xsl:choose>
					<xsl:when test="string(str[@name='title_display'])">
						<xsl:value-of select="str[@name='title_display']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="str[@name='recordId']"/>
					</xsl:otherwise>
				</xsl:choose>
			</title>
			<link href="{$url}id/{str[@name='recordId']}"/>
			<id>
				<xsl:value-of select="str[@name='recordId']"/>
			</id>
			<updated>
				<xsl:value-of select="date[@name='timestamp']"/>
			</updated>

			<link rel="alternate xml" type="text/xml" href="{$url}id/{str[@name='recordId']}.xml"/>
			<link rel="alternate rdf" type="application/rdf+xml" href="{$url}id/{str[@name='recordId']}.rdf"/>

			<!-- treat hoard and non-hoard documents differently -->
			<xsl:choose>
				<xsl:when test="str[@name='recordType'] = 'hoard'">
					<xsl:if test="str[@name='findspot_geo']">
						<link rel="alternate kml" type="application/vnd.google-earth.kml+xml" href="{$url}id/{str[@name='recordId']}.kml"/>
					</xsl:if>

					<xsl:call-template name="geotemp">
						<xsl:with-param name="recordType" select="str[@name='recordType']"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="str[@name='mint_geo']">
						<link rel="alternate kml" type="application/vnd.google-earth.kml+xml" href="{$url}id/{str[@name='recordId']}.kml"/>
					</xsl:if>
					<xsl:call-template name="geotemp">
						<xsl:with-param name="recordType" select="str[@name='recordType']"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</entry>
	</xsl:template>

	<xsl:template match="doc" mode="rss">
		<item>
			<title>
				<xsl:choose>
					<xsl:when test="string(str[@name='title_display'])">
						<xsl:value-of select="str[@name='title_display']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="str[@name='recordId']"/>
					</xsl:otherwise>
				</xsl:choose>
			</title>
			<link>
				<xsl:value-of select="concat($url, 'id/', str[@name='recordId'])"/>
			</link>
			<pubDate>
				<xsl:value-of select="date[@name='timestamp']"/>
			</pubDate>
			<xsl:choose>
				<xsl:when test="str[@name='recordType'] = 'hoard'">
					<xsl:call-template name="geotemp">
						<xsl:with-param name="recordType" select="str[@name='recordType']"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="geotemp">
						<xsl:with-param name="recordType" select="str[@name='recordType']"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</item>
	</xsl:template>

	<xsl:template name="geotemp">
		<xsl:param name="recordType"/>

		<xsl:choose>
			<xsl:when test="str[@name='recordType'] = 'hoard'">
				<xsl:if test="string(str[@name='findspot_geo'])">
					<georss:where>
						<xsl:variable name="tokenized_georef" select="tokenize(str[@name='findspot_geo'], '\|')"/>
						<xsl:variable name="coordinates" select="$tokenized_georef[3]"/>
						<xsl:variable name="lon" select="substring-before($coordinates, ',')"/>
						<xsl:variable name="lat" select="substring-after($coordinates, ',')"/>
						<geo:Point>
							<geo:pos>
								<xsl:value-of select="concat($lat, ' ', $lon)"/>
							</geo:pos>
						</geo:Point>
					</georss:where>
				</xsl:if>
				<xsl:if test="number(int[@name='tpq_num']) and number(int[@name='taq_num'])">
					<gx:TimeSpan>
						<gx:begin>
							<xsl:value-of select="int[@name='tpq_num']"/>
						</gx:begin>
						<gx:end>
							<xsl:value-of select="int[@name='taq_num']"/>
						</gx:end>
					</gx:TimeSpan>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="count(arr[@name='mint_geo']/str) &gt; 0">
					<georss:where>
						<xsl:for-each select="arr[@name='mint_geo']/str">
							<xsl:variable name="tokenized_georef" select="tokenize(., '\|')"/>
							<xsl:variable name="coordinates" select="$tokenized_georef[3]"/>
							<xsl:variable name="lon" select="substring-before($coordinates, ',')"/>
							<xsl:variable name="lat" select="substring-after($coordinates, ',')"/>
							<geo:Point>
								<geo:pos>
									<xsl:value-of select="concat($lat, ' ', $lon)"/>
								</geo:pos>
							</geo:Point>
						</xsl:for-each>
					</georss:where>
				</xsl:if>
				<xsl:if test="count(arr[@name='year_num']/int) &gt; 1">
					<gx:TimeSpan>
						<begin>
							<xsl:value-of select="arr[@name='year_num']/int[1]"/>
						</begin>
						<end>
							<xsl:value-of select="arr[@name='year_num']/int[2]"/>
						</end>
					</gx:TimeSpan>
				</xsl:if>
				<xsl:if test="count(arr[@name='year_num']/int) = 1">
					<gx:TimeStamp>
						<when>
							<xsl:value-of select="arr[@name='year_num']/int"/>
						</when>
					</gx:TimeStamp>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ************************* SOLR-BASED RDF ********************** -->

	<!-- PELAGIOS RDF -->
	<xsl:template match="doc" mode="pelagios" exclude-result-prefixes="#all">
		<xsl:variable name="id" select="str[@name='recordId']"/>
		<xsl:variable name="date" select="date[@name='timestamp']"/>
		<pelagios:AnnotatedThing rdf:about="{$url}pelagios.rdf#{$id}">
			<dcterms:title>
				<xsl:value-of select="str[@name='title_display']"/>
			</dcterms:title>
			<foaf:homepage rdf:resource="{$url}id/{$id}"/>

			<!-- temporal -->
			<xsl:choose>
				<xsl:when test="count(arr[@name='year_num']/int) = 2">
					<dcterms:temporal>start=<xsl:value-of select="min(arr[@name='year_num']/int)"/>; end=<xsl:value-of select="max(arr[@name='year_num']/int)"/></dcterms:temporal>
				</xsl:when>
				<xsl:when test="count(arr[@name='year_num']/int) = 1">
					<dcterms:temporal>start=<xsl:value-of select="arr[@name='year_num']/int"/>; end=<xsl:value-of select="arr[@name='year_num']/int"/></dcterms:temporal>
				</xsl:when>
			</xsl:choose>

			<!-- images -->
			<xsl:if test="str[@name='recordType'] = 'physical'">
				<xsl:if test="string(str[@name='thumbnail_obv'])">
					<xsl:variable name="href">
						<xsl:choose>
							<xsl:when test="contains(str[@name='thumbnail_obv'], 'http://')">
								<xsl:value-of select="str[@name='thumbnail_obv']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat($url, str[@name='thumbnail_obv'])"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<foaf:thumbnail rdf:resource="{$href}"/>
				</xsl:if>
				<xsl:if test="string(str[@name='reference_obv'])">
					<xsl:variable name="href">
						<xsl:choose>
							<xsl:when test="contains(str[@name='reference_obv'], 'http://')">
								<xsl:value-of select="str[@name='reference_obv']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat($url, str[@name='reference_obv'])"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<foaf:depiction rdf:resource="{$href}"/>
				</xsl:if>
				<xsl:if test="string(str[@name='thumbnail_rev'])">
					<xsl:variable name="href">
						<xsl:choose>
							<xsl:when test="contains(str[@name='thumbnail_rev'], 'http://')">
								<xsl:value-of select="str[@name='thumbnail_rev']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat($url, str[@name='thumbnail_rev'])"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<foaf:thumbnail rdf:resource="{$href}"/>
				</xsl:if>
				<xsl:if test="string(str[@name='reference_rev'])">
					<xsl:variable name="href">
						<xsl:choose>
							<xsl:when test="contains(str[@name='reference_rev'], 'http://')">
								<xsl:value-of select="str[@name='reference_rev']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat($url, str[@name='reference_rev'])"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<foaf:depiction rdf:resource="{$href}"/>
				</xsl:if>
			</xsl:if>
		</pelagios:AnnotatedThing>

		<!-- create annotations from pleiades URIs found in nomisma RDF and from findspots -->
		<xsl:for-each select="distinct-values(arr[@name='pleiades_uri']/str)">
			<oa:Annotation rdf:about="{$url}pelagios.rdf#{$id}/annotations/{format-number(position(), '000')}">
				<oa:hasBody rdf:resource="{.}#this"/>
				<oa:hasTarget rdf:resource="{$url}pelagios.rdf#{$id}"/>
				<pelagios:relation rdf:resource="http://pelagios.github.io/vocab/relations#attestsTo"/>
				<oa:annotatedBy rdf:resource="{$url}pelagios.rdf#agents/me"/>
				<oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
					<xsl:value-of select="$date"/>
				</oa:annotatedAt>
			</oa:Annotation>
		</xsl:for-each>

		<!-- create annotations for findspots, but not for coin types -->
		<xsl:if test="not(str[@name='recordType'] = 'conceptual')">
			<xsl:variable name="count" select="count(distinct-values(arr[@name='pleiades_uri']/str))"/>
			<xsl:for-each select="distinct-values(arr[@name='findspot_uri']/str)">
				<oa:Annotation rdf:about="{$url}pelagios.rdf#{$id}/annotations/{format-number($count + 1, '000')}">
					<oa:hasBody rdf:resource="{.}"/>
					<oa:hasTarget rdf:resource="{$url}pelagios.rdf#{$id}"/>
					<pelagios:relation rdf:resource="http://pelagios.github.io/vocab/relations#foundAt"/>
					<oa:annotatedBy rdf:resource="{$url}pelagios.rdf#agents/me"/>
					<oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
						<xsl:value-of select="$date"/>
					</oa:annotatedAt>
				</oa:Annotation>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<!-- NOMISMA COIN TYPE RDF -->
	<xsl:template match="doc" mode="nomisma">
		<xsl:variable name="id" select="str[@name='recordId']"/>
		<xsl:variable name="recordType" select="str[@name='recordType']"/>

		<xsl:element name="nm:{if ($recordType='hoard') then 'hoard' else 'coin'}" namespace="http://nomisma.org/id/" exclude-result-prefixes="#all">			
			<xsl:attribute name="rdf:about" select="concat($url, 'id/', $id)"/>
			<dcterms:title xml:lang="{if (str[@name='lang']) then str[@name='lang'] else 'en'}">
				<xsl:value-of select="str[@name='title_display']"/>
			</dcterms:title>
			<dcterms:identifier>
				<xsl:value-of select="$id"/>
			</dcterms:identifier>
			<dcterms:publisher>
				<xsl:value-of select="str[@name='publisher_display']"/>
			</dcterms:publisher>
			<xsl:for-each select="arr[@name='collection_uri']/str">
				<nm:collection rdf:resource="{.}"/>
			</xsl:for-each>
			<xsl:for-each select="arr[@name='coinType_uri']/str">
				<nm:type_series_item rdf:resource="{.}"/>
			</xsl:for-each>
			<!-- measurements for physical coins -->
			<xsl:if test="int[@name='axis_num']">
				<nm:axis rdf:datatype="xs:integer">
					<xsl:value-of select="int[@name='axis_num']"/>
				</nm:axis>
			</xsl:if>
			<xsl:if test="float[@name='diameter_num']">
				<nm:diameter rdf:datatype="xs:decimal">
					<xsl:value-of select="float[@name='diameter_num']"/>
				</nm:diameter>
			</xsl:if>
			<xsl:if test="float[@name='weight_num']">
				<nm:weight rdf:datatype="xs:decimal">
					<xsl:value-of select="float[@name='weight_num']"/>
				</nm:weight>
			</xsl:if>
			<!-- findspot information -->
			<xsl:if test="int[@name='taq_num']">
				<nm:closing_date rdf:datatype="xs:gYear">
					<xsl:value-of select="format-number(int[@name='taq_num'], '0000')"/>
				</nm:closing_date>
			</xsl:if>
			<xsl:if test="arr[@name='findspot_geo']/str">
				<xsl:variable name="findspot" select="tokenize(arr[@name='findspot_geo']/str, '\|')"/>
				<xsl:choose>
					<xsl:when test="contains($findspot[2], 'nomisma.org')">
						<nm:findspot rdf:resource="{$findspot[2]}"/>
					</xsl:when>
					<xsl:otherwise>
						<nm:findspot>
							<rdf:Description rdf:about="{$findspot[2]}">
								<geo:lat>
									<xsl:value-of select="substring-after($findspot[3], ',')"/>
								</geo:lat>
								<geo:long>
									<xsl:value-of select="substring-before($findspot[3], ',')"/>
								</geo:long>
							</rdf:Description>
						</nm:findspot>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			<!-- images -->	
			<!-- obverse -->			
			<xsl:if test="string(str[@name='reference_obv']) or string(str[@name='thumbnail_obv'])">
				<nm:obverse>
					<rdf:Description>
						<xsl:if test="string(str[@name='reference_obv'])">
							<xsl:variable name="href">
								<xsl:choose>
									<xsl:when test="contains(str[@name='reference_obv'], 'http://')">
										<xsl:value-of select="str[@name='reference_obv']"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($url, str[@name='reference_obv'])"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>							
							<foaf:depiction rdf:resource="{$href}"/>
						</xsl:if>
						<xsl:if test="string(str[@name='thumbnail_obv'])">
							<xsl:variable name="href">
								<xsl:choose>
									<xsl:when test="contains(str[@name='thumbnail_obv'], 'http://')">
										<xsl:value-of select="str[@name='thumbnail_obv']"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($url, str[@name='thumbnail_obv'])"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>						
							<foaf:thumbnail rdf:resource="{$href}"/>
						</xsl:if>
					</rdf:Description>					
				</nm:obverse>
			</xsl:if>
			<!-- reverse -->
			<xsl:if test="string(str[@name='reference_rev']) or string(str[@name='thumbnail_rev'])">
				<nm:reverse>
					<rdf:Description>
						<xsl:if test="string(str[@name='reference_rev'])">
							<xsl:variable name="href">
								<xsl:choose>
									<xsl:when test="contains(str[@name='reference_rev'], 'http://')">
										<xsl:value-of select="str[@name='reference_rev']"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($url, str[@name='reference_rev'])"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>							
							<foaf:depiction rdf:resource="{$href}"/>
						</xsl:if>
						<xsl:if test="string(str[@name='thumbnail_rev'])">
							<xsl:variable name="href">
								<xsl:choose>
									<xsl:when test="contains(str[@name='thumbnail_rev'], 'http://')">
										<xsl:value-of select="str[@name='thumbnail_rev']"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($url, str[@name='thumbnail_rev'])"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>							
							<foaf:thumbnail rdf:resource="{$href}"/>
						</xsl:if>
					</rdf:Description>					
				</nm:reverse>
			</xsl:if>
		</xsl:element>
	</xsl:template>

	<!-- ********************** FUNCTIONS ********************** -->
	<xsl:function name="numishare:iso-to-digit">
		<xsl:param name="year"/>

		<xsl:choose>
			<xsl:when test="number($year) &lt;= 0">
				<xsl:value-of select="number($year) - 1"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="number($year)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
</xsl:stylesheet>
