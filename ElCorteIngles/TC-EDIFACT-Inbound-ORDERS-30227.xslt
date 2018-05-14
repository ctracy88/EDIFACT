<?xml version="1.0"?>
<!--
	XSLT to transform an El Corte Ingles Edifact Purchase Order message into El Corte Ingles TC XML.
	
	Input: EDIFACT D93AORDER.
	Output: TC XML Order.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: 10/20/2016
	
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
			<TransactionType>
				<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
			</TransactionType>
			<PONumber>
				<xsl:value-of select="edi:getSubElement(BGM, 2, 1)"/>
			</PONumber>
			<Purpose>
				<xsl:value-of select="edi:getElement(BGM, 3)"/>
			</Purpose>
			<DTM>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</DocDate>
				<RequestedDeliveryDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
				</RequestedDeliveryDate>
				<LatestDelivery>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
				</LatestDelivery>
			</DTM>
			<ALI>
				<SpecialConditionCode>
					<xsl:value-of select="edi:getElement(ALI, 1)"/>
				</SpecialConditionCode>
			</ALI>
			<FTX>
				<xsl:for-each select="FTX">
					<Note><xsl:value-of select="edi:getSubElement(., 4, 1)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 2)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 3)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 4)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 5)"/></Note>
				</xsl:for-each>
			</FTX>
			<RFF>
				<OrderSeason>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AAN'], 1, 2)"/>
				</OrderSeason>
				<SaleUnecoCode>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'SD'], 1, 2)"/>
				</SaleUnecoCode>
			</RFF>
			<!-- Start of NADs></!-->
			<xsl:variable name="Issuer" select="NAD[Field[1] = 'MS']"/>
			<xsl:variable name="Receipient" select="NAD[Field[1] = 'MR']"/>
			<xsl:variable name="Supplier" select="NAD[Field[1] = 'SU']"/>
			<xsl:variable name="DeliveryParty" select="NAD[Field[1] = 'DP']"/>
			<xsl:variable name="BuyingParty" select="NAD[Field[1] = 'BY']"/>
			<xsl:variable name="Invoicee" select="NAD[Field[1] = 'IV']"/>
						
			<Issuer>
				<Code>
					<xsl:value-of select="edi:getSubElement($Issuer, 2, 1)"/>
				</Code>
			</Issuer>
			<Receipient>
				<Code>
					<xsl:value-of select="edi:getSubElement($Receipient, 2, 1)"/>
				</Code>
			</Receipient>
			<Supplier>
				<Code>
					<xsl:value-of select="edi:getSubElement($Supplier, 2, 1)"/>
				</Code>
			</Supplier>
			<DeliveryParty>
				<Code>
					<xsl:value-of select="edi:getSubElement($DeliveryParty, 2, 1)"/>
				</Code>
			</DeliveryParty>
			<BuyingParty>
				<Code>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 2, 1)"/>
				</Code>
				<RFF>
					<BuyingUnecoCode>
						<xsl:value-of select="edi:getSubElement($BuyingParty/RFF[Field[1]/Field[1] = 'API'], 1, 2)"/>
					</BuyingUnecoCode>
					<FinalDestinationCode>
						<xsl:value-of select="edi:getSubElement($BuyingParty/RFF[Field[1]/Field[1] = 'ZZZ'], 1, 2)"/>
					</FinalDestinationCode>
				</RFF>
			</BuyingParty>
			<Invoicee>
				<Code>
					<xsl:value-of select="edi:getSubElement($Invoicee, 2, 1)"/>
				</Code>
			</Invoicee>
			<!--END NADs -->	
			<TAX>
				<TaxPercent>
					<xsl:value-of select="edi:getSubElement(TAX, 5, 4)"/>
				</TaxPercent>
			</TAX>
			<CUX>
				<CurrencyType>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 1)"/>
				</CurrencyType>
			</CUX>
			<PAT>
				<TermsNetDaysDue>
					<xsl:value-of select="edi:getSubElement(PAT, 3, 4)"/>
				</TermsNetDaysDue>
				<DTM>
					<TermsDeliveryDate>
						<xsl:value-of select="edi:getSubElement(PAT/DTM[Field[1]/Field[1] = '7'], 1, 2)"/>
					</TermsDeliveryDate>
				</DTM>
			</PAT>
			<TDT>
				<TransportStageCodeQual>
					<xsl:value-of select="edi:getElement(TDT, 1)"/>
				</TransportStageCodeQual>
			</TDT>
			<TOD>
				<DeliveryTransportTerms>
					<xsl:value-of select="edi:getSubElement(TOD, 3, 1)"/>
				</DeliveryTransportTerms>
			</TOD>
			<!-- do the order lines -->
			<xsl:apply-templates select="LIN"/>
			<MOA>
				<TotalLineItems>
					<xsl:value-of select="edi:getSubElement(MOA[Field[1]/Field[1] = '79'], 1, 2)"/>
				</TotalLineItems>
				<OriginalAmount>
					<xsl:value-of select="edi:getSubElement(MOA[Field[1]/Field[1] = '98'], 1, 2)"/>
				</OriginalAmount>
			</MOA>
		</PurchaseOrder>
	</xsl:template>
	<xsl:template match="LIN">
		<Items>
			<LIN>
				<LineNum>
					<xsl:value-of select="edi:getElement(self::node(), 1)"/>
				</LineNum>
				<ItemNumType>
					<xsl:value-of select="edi:getSubElement(self::node(), 3, 2)"/>
				</ItemNumType>
				<ItemNum>
					<xsl:value-of select="edi:getSubElement(self::node(), 3, 1)"/>
				</ItemNum>
				<PIA>
					<BuyersItemNum>
						<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'IN'], 2, 1)"/>
					</BuyersItemNum>
					<PackagingUnitCode>
						<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'ADU'], 2, 1)"/>
					</PackagingUnitCode>
				</PIA>
				<IMD>
					<DescriptionType>
						<xsl:value-of select="edi:getSubElement(IMD[Field[1] = 'C'], 3, 1)"/>
					</DescriptionType>
					<Description>
						<xsl:value-of select="edi:getSubElement(IMD[Field[2] = 'DSC'], 3, 4)"/>
					</Description>
					<ModelDescription>
						<xsl:value-of select="edi:getSubElement(IMD[Field[2] = 'BRN'], 3, 4)"/>
					</ModelDescription>
					<Variety1>
						<xsl:value-of select="edi:getSubElement(IMD[Field[2] = '35'], 3, 4)"/>
					</Variety1>
					<Variety2>
						<xsl:value-of select="edi:getSubElement(IMD[Field[2] = 'UP5'], 3, 4)"/>
					</Variety2>
					<PresentationQtyFormat>
						<xsl:value-of select="edi:getSubElement(IMD[Field[2] = 'U03'], 3, 4)"/>
					</PresentationQtyFormat>
				</IMD>
				<QTY>
					<QtyOrdered>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '21'], 1, 2)"/>
					</QtyOrdered>
					<QtyPerPack>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '59'], 1, 2)"/>
					</QtyPerPack>
				</QTY>
				<MOA>
					<LineItemAmt>
						<xsl:value-of select="edi:getSubElement(MOA[Field[1]/Field[1] = '203', 1, 2)"/>
					</LineItemAmt>
				</MOA>
				<FTX>
				<xsl:for-each select="FTX">
					<Note><xsl:value-of select="edi:getSubElement(., 4, 1)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 2)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 3)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 4)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 5)"/></Note>
				</xsl:for-each>
				</FTX>
				<PRI>
					<Price>
						<xsl:value-of select="edi:getSubElement(PRI[Field[1]/Field[1] = 'AAB'], 1, 2)"/>
					</Price>
					<NetPrice>
						<xsl:value-of select="edi:getSubElement(PRI[Field[1]/Field[1] = 'AAA'], 1, 2)"/>
					</NetPrice>
				</PRI>
				<TAX>
					<AlcoholTaxRate>
						<xsl:value-of select="edi:getSubElement(TAX[Field[2]/Field[1] = 'ACT'], 5, 4)"/>
					</AlcoholTaxRate>
					<AlcoholTaxAmount>
						<xsl:value-of select="edi:getSubElement(TAX/MOA[Field[1]/Field[1] = '124'], 1, 2)"/>
					</AlcoholTaxAmount>
				</TAX>
			</LIN>
		</Items>
	</xsl:template>
</xsl:stylesheet>
