<?xml version="1.0"?>
<!--
	XSLT to transform an Edifact INSDS message into TC XML.
	
	Input: EDIFACT D96A INSDES
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
			<DTM>
				<DateEffective>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '7'], 1, 2)"/>
				</DateEffective>
				<PostDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '202'], 1, 2)"/>
				</PostDate>
				<MessageDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</MessageDate>
				<DateReceived>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '50'], 1, 2)"/>
				</DateReceived>
				<TransactionDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '11'], 1, 2)"/>
				</TransactionDate>
				<RequestedDeliveryDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '17'], 1, 2)"/>
				</RequestedDeliveryDate>
			</DTM>
			<RFF>
				<OrderNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'VN'], 1, 2)"/>
				</OrderNum>
				<DepositorOrderNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
				</DepositorOrderNum>
				<ReportingTypeCode>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ALE'], 1, 2)"/>
				</ReportingTypeCode>
				<AccountingID>
						<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ADE'], 1, 2)"/>
				</AccountingID>
				<WarehouseReceipt>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'WR'], 1, 2)"/>
				</WarehouseReceipt>
			</RFF>
			<NAD.SF>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SF'], 2, 1)"/>
				</Code>
				<LOC>
					<PlaceOfDespatchID>
						<xsl:value-of select="edi:getSubElement(NAD/LOC[Field[1] = '80'], 2, 1)"/>
					</PlaceOfDespatchID>
					<PlaceOfDespatchCode>
						<xsl:value-of select="edi:getSubElement(NAD/LOC[Field[1] = '80'], 2, 4)"/>
					</PlaceOfDespatchCode>
					<PlaceOfDespatchRelatedLoc>
						<xsl:value-of select="edi:getSubElement(NAD/LOC[Field[1] = '80'], 3, 1)"/>
					</PlaceOfDespatchRelatedLoc>
				</LOC>
			</NAD.SF>
			<NAD.MR>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'MR'], 2, 1)"/>
				</Code>
			</NAD.MR>
			<NAD.FR>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'FR'], 2, 1)"/>
				</Code>
			</NAD.FR>
			<ShipTo>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'DP'], 2, 1)"/>
				</Code>
			</ShipTo>
			<!-- do the order lines -->
			<xsl:apply-templates select="LIN"/>
		</PurchaseOrder>
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
				<PIA>
					<SuppliersArticleNum>
						<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'SA'], 2, 1)"/>
					</SuppliersArticleNum>
					<VendorItemNum>
						<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'MF'], 2, 1)"/>
					</VendorItemNum>
				</PIA>
				<QTY>
					<Qty>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '21'], 1, 2)"/>
					</Qty>
					<QtyOrdered>
						<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '46'], 1, 2)"/>
					</QtyOrdered>
				</QTY>
				<GIN>
					<SSCC>
						<xsl:value-of select="edi:getElement(GIN[Field[1] = 'BJ'], 2)"/>
					</SSCC>
					<LotNum>
						<xsl:value-of select="edi:getElement(GIN[Field[1] = 'BX'], 2)"/>
					</LotNum>
				</GIN>
				<DTM>
					<ContractExpireDate>
						<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '36'], 1, 2)"/>
					</ContractExpireDate>
				</DTM>
				<RFF>
					<BatchLotNum>
						<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'BT'], 1, 2)"/>
					</BatchLotNum>
					<OrderNum>
						<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'VN'], 1, 2)"/>
					</OrderNum>
				</RFF>
				<NAD.DP>
					<Code>
						<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'DP'], 2, 1)"/>
					</Code>
					<LOC>
						<PlaceOfDeliveryID>
							<xsl:value-of select="edi:getSubElement(NAD/LOC[Field[1] = '7'], 2, 1)"/>
						</PlaceOfDeliveryID>
						<PlaceOfDeliveryCode>
							<xsl:value-of select="edi:getSubElement(NAD/LOC[Field[1] = '7'], 2, 4)"/>
						</PlaceOfDeliveryCode>
						<PlaceOfDeliveryRelatedLoc>
							<xsl:value-of select="edi:getSubElement(NAD/LOC[Field[1] = '7'], 3, 1)"/>
						</PlaceOfDeliveryRelatedLoc>
					</LOC>
				</NAD.DP>
				<NAD.SF>
					<Code>
						<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SF'], 2, 1)"/>
					</Code>
				</NAD.SF>
			</LIN>
		</Items>
	</xsl:template>
</xsl:stylesheet>
