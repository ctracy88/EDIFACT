<?xml version="1.0"?>
<!--
	XSLT to transform an Edifact INVRPT message into TC XML.
	
	Input: EDIFACT D96A INVRPT
	Output: TC XML
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: August 30, 2016
	
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"				
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
                xmlns:edi="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension"
                xmlns:file="com.css.base.xml.xslt.ext.XsltFileExtension"
		xmlns:mapper="com.api.tx.MapperEngine"
                extension-element-prefixes="date math mapper edi file">
                
	<xsl:output method="xml"/>

	<xsl:param name="Outbox"/>

  <xsl:template match="/">
		<xsl:if test="count(/Document/UNB) &gt; 1">
			<mapper:logError>
				Multiple envelopes is Unsupported.
			</mapper:logError>
		</xsl:if>
		
		<xsl:variable name="filename">
			<xsl:value-of select="concat(mapper:getVar('$$SourceFile'), '.', position(), '.order.xml')"/>
		</xsl:variable>

		<!-- This will ensure it is deleted if an error occurs -->
		<mapper:registerCreatedFile>
			<xsl:value-of select="concat($Outbox, '/', $filename)"/>
		</mapper:registerCreatedFile>

		<file:save name="$filename" path="$Outbox" append="false" returnData="false" type="xml">
		<Batch>
			<xsl:apply-templates select="/Document/UNB/UNH | /Document/UNB/UNG/UNH">
				<xsl:with-param name="envelope" select="/Document/UNB"/>
			</xsl:apply-templates>
		</Batch>
		</file:save>
	</xsl:template>


	<xsl:template match="UNH">
		<xsl:param name="envelope"/>

		<InventoryReport>
			<BatchReferences>
				<xsl:attribute name="test">
					<xsl:choose>
						<xsl:when test="edi:getElement($envelope, 11) = '1'">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				
				<Number><xsl:value-of select="edi:getElement(., 1)"/></Number>
				<Version>1</Version>
				<Date>
					<date:reformat curFormat="yyMMdd" newFormat="yyyy-MM-dd">
						<xsl:value-of select="edi:getSubElement($envelope, 4, 1)"/>
					</date:reformat>
				</Date>
				
				<SenderCode><xsl:value-of select="edi:getSubElement($envelope, 2, 1)"/></SenderCode>
				<SenderCodeQualifier><xsl:value-of select="edi:getSubElement($envelope, 2, 2)"/></SenderCodeQualifier>
				<SenderName></SenderName>
				<ReceiverCode><xsl:value-of select="edi:getSubElement($envelope, 3, 1)"/></ReceiverCode>
				<ReceiverCodeQualifier><xsl:value-of select="edi:getSubElement($envelope, 3, 2)"/></ReceiverCodeQualifier>
				<ReceiverName></ReceiverName>
				<BatchRef><xsl:value-of select="edi:getElement($envelope, 5)"/></BatchRef>
			</BatchReferences>
			<BGM>
				<TransactionNoteType>
					<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
				</TransactionNoteType>
				<DocumentNumber>
					<xsl:value-of select="edi:getSubElement(BGM, 2, 1)"/>
				</DocumentNumber>
				<DocumentType>
					<xsl:value-of select="edi:getElement(BGM, 3)"/>
				</DocumentType>
			</BGM>
			<DTM>
				<DateEffective>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '7'], 1, 2)"/>
				</DateEffective>
				<PostDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '202'], 1, 2)"/>
				</PostDate>
			</DTM>
			<!-- do the order lines -->
			<xsl:apply-templates select="LIN"/>
		</InventoryReport>
	</xsl:template>
	<xsl:template match="LIN">
		<Items>
			<LIN>
				<LineNum>
					<xsl:value-of select="edi:getElement(self::node(), 1)"/>
				</LineNum>
				<EANNum>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'EN'], 3, 1)"/>
				</EANNum>
			</LIN>
			<PIA>
				<SuppliersArticleNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'SA'], 2, 1)"/>
				</SuppliersArticleNum>
			</PIA>
			<QTY>
				<QtyAvailable>
					<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[3] = 'U']  , 1, 2)"/>
				</QtyAvailable>
				<QtyQuarantine>
					<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[3] = 'Q']  , 1, 2)"/>
				</QtyQuarantine>
				<QtyDamaged>
					<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[3] = 'S']  , 1, 2)"/>
				</QtyDamaged>
			</QTY>
			<GIN>
				<LotNumber>
					<xsl:value-of select="edi:getElement(GIN[Field[1] = 'BX'],  2)"/>
				</LotNumber>
			</GIN>
			<LOC>
				<LocationOfGoods>
					<xsl:value-of select="edi:getSubElement(LOC[Field[1] = '14'], 2, 4)"/>
				</LocationOfGoods>
				<StockStatusCode>
					<xsl:value-of select="edi:getSubElement(LOC[Field[1] = '14'], 3, 4)"/>
				</StockStatusCode>
			</LOC>
			<DTM>
				<ExpirationDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '36'], 1, 2)"/>
				</ExpirationDate>
			</DTM>
		</Items>
	</xsl:template>
</xsl:stylesheet>
