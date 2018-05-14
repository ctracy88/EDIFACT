<?xml version="1.0"?>
<!--
	XSLT to transform a General Motors D97A APERAK into TC XML.
	
	Input: General Motors D97A APERA
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
				<ResponseTypeCode>
					<xsl:value-of select="edi:getElement(BGM, 4)"/>
				</ResponseTypeCode>
			</BGM>
			<DTM>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '97'], 1, 2)"/>
				</DocDate>
			</DTM>
			<FTX>
				<TransactionRespondedTo>
					<xsl:value-of select="edi:getSubElement(FTX[Field[1] = 'AAP'], 3, 1)"/>
				</TransactionRespondedTo>
			</FTX>
			<RFF>
				<TransactionRefNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'TN'], 1, 2)"/>
				</TransactionRefNum>
			</RFF>
			<!-- Start of NADs></!-->
			<xsl:variable name="NAD.FR" select="NAD[Field[1] = 'FR']"/>
			<xsl:variable name="NAD.MR" select="NAD[Field[1] = 'MR']"/>	
			<NAD.FR>
				<Code>
					<xsl:value-of select="edi:getSubElement($NAD.FR, 2, 1)"/>
				</Code>
			</NAD.FR>
			<NAD.MR>
				<Code>
					<xsl:value-of select="edi:getSubElement($NAD.MR, 2, 1)"/>
				</Code>
			</NAD.MR>
			<Item>
				<ERC>
					<Status>
						<xsl:value-of select="edi:getSubElement(ERC[Field[1]/Field[3] = '116'], 1, 1)"/>
					</Status>
					<RFF>
						<PartNum>
							<xsl:value-of select="edi:getSubElement(ERC/RFF[Field[1]/Field[1] = 'ABU'], 1, 2)"/>
						</PartNum>
						<BuyersOrderNum>
							<xsl:value-of select="edi:getSubElement(ERC/RFF[Field[1]/Field[1] = 'CO'], 1, 2)"/>
						</BuyersOrderNum>
					</RFF>
					<FTX>
						<ErrorDescription>
							<xsl:value-of select="edi:getSubElement(ERC/FTX[Field[1]/Field[1] = 'AAO'], 4, 1)"/>
						</ErrorDescription>
						<DiscrepancyInfo>
							<xsl:value-of select="edi:getSubElement(ERC/FTX[Field[1]/Field[1] = 'ABO'], 4, 1)"/>
						</DiscrepancyInfo>
					</FTX>
				</ERC>
			</Item>			
		</PurchaseOrder>
	</xsl:template>
</xsl:stylesheet>
