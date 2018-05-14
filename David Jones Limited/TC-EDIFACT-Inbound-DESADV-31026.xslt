<?xml version="1.0"?>
<!--
	Map to turn a Edifact D97A Desadv into a Generic XML version
		
	Input:  Edifact D97A DESADV
	Output: Generic XML Forecast.
	
	Author: Charlie Tracy
	Version: 1.0
	Creation Date: 18-June-2015
	
	Last Modified Date: 
	Last Modified By: 
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"				
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
                xmlns:edi="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension"
		            xmlns:mapper="com.api.tx.MapperEngine"
                xmlns:file="com.css.base.xml.xslt.ext.XsltFileExtension"
                extension-element-prefixes="date math mapper edi file">

	<xsl:output method="xml"/>

	<xsl:param name="Outbox"/>

	<xsl:template match="/">
		<xsl:if test="count(/Document/UNB) &gt; 1">
			<mapper:logError>
				Call Roy Hocknull.
			</mapper:logError>
		</xsl:if>
		<xsl:variable name="filename">
			<xsl:value-of select="concat(mapper:getVar('$$SourceFile'), '.', position(), '.order.xml')"/>
		</xsl:variable>

		<mapper:registerCreatedFile>
			<xsl:value-of select="concat($Outbox, '/', $filename)"/>
		</mapper:registerCreatedFile>

		<file:save name="$filename" path="$Outbox" append="false" returnData="false" type="xml"> 
			<Batch>
				<xsl:apply-templates select="/Document/UNB/UNH">
					<xsl:with-param name="envelope" select="/Document/UNB"/>
				</xsl:apply-templates>
			</Batch>
		</file:save>
 	</xsl:template>


	<xsl:template match="UNH">
		<xsl:param name="envelope"/>
		
		<xsl:variable name="packageCount" />

		<ASN>
			<xsl:attribute name="number">
				<xsl:value-of select="edi:getElement(., 1)"/>
			</xsl:attribute>
			<xsl:attribute name="version">1</xsl:attribute>
			<xsl:attribute name="type">ASN</xsl:attribute>
			<BatchReferences>
				<xsl:choose>
					<xsl:when test="edi:getElement($envelope, 11) = '1'">
						<test>true</test>
					</xsl:when>
					<xsl:otherwise>
						<test>false</test>
					</xsl:otherwise>
				</xsl:choose>
				<RefNumber>
					<xsl:value-of select="edi:getElement(., 1)"/>
				</RefNumber>
				<Version>1</Version>
				<Date>
					<date:reformat curFormat="yyMMdd" newFormat="yyyy-MM-dd">
						<xsl:value-of select="edi:getSubElement($envelope, 4, 1)"/>
					</date:reformat>
				</Date>				
				<SenderCode>
					<xsl:value-of select="edi:getSubElement($envelope, 2, 1)"/>
				</SenderCode>
				<SenderCodeQualifier>
					<xsl:value-of select="edi:getSubElement($envelope, 2, 2)"/>
				</SenderCodeQualifier>
				<SenderName/>
				<ReceiverCode>
					<xsl:value-of select="edi:getSubElement($envelope, 3, 1)"/>
				</ReceiverCode>
				<ReceiverCodeQualifier>
					<xsl:value-of select="edi:getSubElement($envelope, 3, 2)"/>
				</ReceiverCodeQualifier>
				<ReceiverName/>
				<BatchRef>
					<xsl:value-of select="edi:getElement($envelope, 5)"/>
				</BatchRef>
				<TransType>
					<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
				</TransType>
				<Purpose>
					<xsl:value-of select="edi:getElement(BGM, 3)"/>
				</Purpose>
				<DocNum>
					<xsl:value-of select="edi:getElement(BGM, 2)"/>
				</DocNum>
			</BatchReferences>
			<BGM>
				<TransactionNoteType>
					<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
				</TransactionNoteType>
				<ShippingShipmentID>
					<xsl:value-of select="edi:getElement(BGM ,2)"/>
				</ShippingShipmentID>
				<TransactionPurpose>
					<xsl:value-of select="edi:getElement(BGM ,3)"/>
				</TransactionPurpose>
			</BGM>
			<DTM>
				<DateRequestedShip>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '11'], 1, 2)"/>
				</DateRequestedShip>
				<EstDeliveryDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '17'], 1, 2)"/>
				</EstDeliveryDate>
				<TransCreateDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</TransCreateDate>
			</DTM>
			<RFF>
				<PurchaseOrderNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1,2)"/>
				</PurchaseOrderNumber>
				<VendorOrderNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'VN'], 1,2)"/>
				</VendorOrderNumber>
				<OrderType>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'CR'], 1,2)"/>
				</OrderType>
				<BougheyDeliveryNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'DQ'], 1,2)"/>
				</BougheyDeliveryNumber>
				<ResponseNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'POR'], 1,2)"/>
				</ResponseNumber>
				<DTM>
				<PODate>
					<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '171'], 1, 2)"/>
				</PODate>
				</DTM>
			</RFF>
			<NAD.SU>
				<Code>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 2)"/>
				</Code>
			</NAD.SU>
			<NAD.ST>
				<Code>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'ST'], 2)"/>
				</Code>
			</NAD.ST>
			<TOD>
				<TermsType>
					<xsl:value-of select="edi:getElement(TOD ,1)"/>
				</TermsType>
			</TOD>
			<xsl:for-each select="CPS">
				<xsl:call-template name="processCPS">
					<xsl:with-param name="CPS" select="."/>
				</xsl:call-template>
			</xsl:for-each>
		</ASN>
	</xsl:template>	
	

	<xsl:template name="processCPS">
		<xsl:param name="CPS"/>
		<xsl:variable name="pack" select="edi:getElement($CPS,2)"/>
		<!-- If Pack Loop -->
		<xsl:if test="string-length($pack) = 0">
		
			<Pack>
				<ShippingNumberOfCartons>
					<xsl:value-of select="edi:getElement(PAC ,1)"/>
				</ShippingNumberOfCartons>	
			</Pack>
		</xsl:if>
		<!-- If Item Loop -->
		<xsl:if test="string-length($pack) &gt; 0">
			<Item>
				<Details>
					<CartonCountCalc1>
						<xsl:value-of select="edi:getElement(PAC, 1)"/>
					</CartonCountCalc1>
					<CartonCountCalc10>
						<xsl:value-of select="edi:getElement(PCI, 1)"/>
					</CartonCountCalc10>
					<ItemVendorNumber>
						<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'VN'], 1, 2)"/>
					</ItemVendorNumber>
					<ItemExpirationDate>
						<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '36'], 1, 2)"/>
					</ItemExpirationDate>
					<ItemBatchNumber>
						<xsl:value-of select="edi:getElement(GIN[Field[1] = 'BJ'], 2)"/>
					</ItemBatchNumber>
					<LineNum>
						<xsl:value-of select="edi:getElement(LIN, 1)"/>
					</LineNum>
					<ItemEuropeanArticleNumber>
						<xsl:value-of select="edi:getSubElement(LIN[Field[3]/Field[2] = 'EN'], 3, 1)"/>
					</ItemEuropeanArticleNumber>
					<ItemQuantity>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '12'], 1, 2)"/>
					</ItemQuantity>
					<SupplierArticleNum>
						<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'SA'], 2, 1)"/>
					</SupplierArticleNum>
					<QtyDifference>
						<xsl:value-of select="edi:getElement(QVR, 1)"/>
					</QtyDifference>
					<QtyShipped>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '93'], 1, 2)"/>
					</QtyShipped>
					<QtyOrdered>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '142'], 1, 2)"/>
					</QtyOrdered>
				</Details>
			</Item>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
