<?xml version="1.0"?>
<!--
	XSLT to transform an Edifact APERAK message 

	
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

		<PurchaseOrder>
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
				<TransactionID>
					<xsl:value-of select="edi:getElement(BGM, 2)"/>
				</TransactionID>
				<Purpose>
					<xsl:value-of select="edi:getElement(BGM, 3)"/>
				</Purpose>
			</BGM>
			<DTM>
				<CreationDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '97'], 1, 2)"/>
				</CreationDate>
			</DTM>
			<RFF>
				<InvoiceNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'IV'], 1, 2)"/>
				</InvoiceNumber>
				<SIDShippersID>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'SI'], 1, 2)"/>
				</SIDShippersID>
				<DespatchAdvice>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AAK'], 1, 2)"/>
				</DespatchAdvice>
				<DTM>
					<InvoiceDate>
						<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '3'], 1, 2)"/>
					</InvoiceDate>
					<DespatchDate>
						<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '11'], 1, 2)"/>
					</DespatchDate>
				</DTM>
			</RFF>
			<!-- Start of NADs></!-->
			<xsl:variable name="NAD.SF" select="NAD[Field[1] = 'SF']"/>
			<xsl:variable name="NAD.ST" select="NAD[Field[1] = 'ST']"/>	
			<NAD.SF>
				<Code>
					<xsl:value-of select="edi:getSubElement($NAD.SF, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($NAD.SF, 4, 1)"/>
				</Name>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($NAD.SF, 2, 3)"/>
				</CodeType>
			</NAD.SF>
			<NAD.ST>
				<Code>
					<xsl:value-of select="edi:getSubElement($NAD.ST, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($NAD.ST, 4, 1)"/>
				</Name>
				<CodeType>
					<xsl:value-of select="edi:getSubElement($NAD.ST, 2, 3)"/>
				</CodeType>
			</NAD.ST>
			<Item>
				<ERC>
					<Status>
						<xsl:value-of select="edi:getSubElement(ERC[Field[1]/Field[3] = '116'], 1, 1)"/>
					</Status>
					<FTX>
						<ErrorDescription>
							<xsl:value-of select="edi:getSubElement(ERC/FTX, 4, 1)"/>
						</ErrorDescription>
						<SegmentElementinError>
							<xsl:value-of select="edi:getSubElement(ERC/FTX, 4, 2)"/>
						</SegmentElementinError>
						<CopyofBadData>
							<xsl:value-of select="edi:getSubElement(ERC/FTX, 4, 3)"/>
						</CopyofBadData>
					</FTX>
				</ERC>
			</Item>			
		</PurchaseOrder>
	</xsl:template>
</xsl:stylesheet>
