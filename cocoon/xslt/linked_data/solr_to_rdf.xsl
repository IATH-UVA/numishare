<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs nuds nh xlink mets"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:nm="http://nomisma.org/id/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:nuds="http://nomisma.org/nuds" xmlns:nh="http://nomisma.org/nudsHoard"
	xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:georss="http://www.georss.org/georss"
	xmlns:atom="http://www.w3.org/2005/Atom" xmlns:oa="http://www.w3.org/ns/oa#" xmlns:owl="http://www.w3.org/2002/07/owl#"
	xmlns:dc="http://purl.org/dc/terms/" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:mets="http://www.loc.gov/METS/"
	xmlns:foaf="http://xmlns.com/foaf/0.1/" version="2.0">
	<xsl:include href="templates.xsl"/>
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	<xsl:param name="mode"/>

	<xsl:param name="url" select="/content/config/url"/>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:choose>
				<xsl:when test="$mode='pelagios'">
					<foaf:Organization rdf:about="{$url}pelagios.rdf#agents/me">
						<foaf:name>
							<xsl:value-of select="/content/config/template/agencyName"/>
						</foaf:name>
					</foaf:Organization>
					<xsl:apply-templates select="//doc" mode="pelagios"/>
				</xsl:when>
				<xsl:when test="$mode='nomisma'">
					<xsl:apply-templates select="//doc" mode="nomisma"/>
				</xsl:when>
			</xsl:choose>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
