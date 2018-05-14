<?xml version="1.0"?>
<!--
	XSLT to transform a General Motors D97A INVRPT message into TC XML.
	
	Input: General Motors D97A INVRPT
	Output: TC XML
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: 11/4/2016
	
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
			</BGM>
			<DTM>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</DocDate>
			</DTM>
			<Issuer>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1]/Field[1] = 'MI'], 2, 3)"/>
				</CodeType>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1]/Field[1] = 'MI'], 2, 1)"/>
				</Code>
			</Issuer>
			<Supplier>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1]/Field[1] = 'SU'], 2, 3)"/>
				</CodeType>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1]/Field[1] = 'SU'], 2, 1)"/>
				</Code>
			</Supplier>
			<!-- do the order lines -->
			<xsl:apply-templates select="LIN"/>
		</InventoryReport>
	</xsl:template>
	<xsl:template match="LIN">
		<Items>
			<LIN>
				<BuyersItemNum>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'IN'], 3, 1)"/>
				</BuyersItemNum>
				<PIA>
					<VendorPartNum>
						<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'VP'], 2, 1)"/>
					</VendorPartNum>
				</PIA>
				<DTM>
					<OldestBackorderDate>
						<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '4'], 1, 2)"/>
					</OldestBackorderDate>
					<PromisedForDate>
						<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '79'], 1, 2)"/>
					</PromisedForDate>
				</DTM>
				<INV>
					<InventoryAffectedCode>
						<xsl:value-of select="edi:getElement(INV, 2)"/>
					</InventoryAffectedCode>
					<QTY>
						<BackorderQty>
							<xsl:value-of select="edi:getSubElement(INV/QTY[Field[1]/Field[1] = '83'], 1, 2)"/>
						</BackorderQty>
					</QTY>
				</INV>
			</LIN>
		</Items>
	</xsl:template>
</xsl:stylesheet>
