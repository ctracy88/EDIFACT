<?xml version="1.0"?>
<!--
	XSLT to transform an Edifact HANMOV message into TC XML.
	
	Input: EDIFACT D96A HANMOV
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
				<PickupDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '200'], 1, 2)"/>
				</PickupDate>
				<DespatchDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '11'], 1, 2)"/>
				</DespatchDate>
			</DTM>
			<RFF>
				<VendorOrderNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'VN'], 1, 2)"/>
				</VendorOrderNumber>
				<POResponseNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'POR'], 1, 2)"/>
				</POResponseNum>
				<RefCustomerNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'CR'], 1, 2)"/>
				</RefCustomerNum>
			</RFF>
			<NAD.SF>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SF'], 2, 1)"/>
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
				<RFF>
					<ApplicableInstructions>
						<xsl:value-of select="edi:getSubElement(NAD/RFF[Field[1]/Field[1] = 'AEH'], 1, 2)"/>
					</ApplicableInstructions>
					<AckOfOrderNum>
						<xsl:value-of select="edi:getSubElement(NAD/RFF[Field[1]/Field[1] = 'AAA'], 1, 2)"/>
					</AckOfOrderNum>
					<MarkingLabelRef>
						<xsl:value-of select="edi:getSubElement(NAD/RFF[Field[1]/Field[1] = 'AFF'], 1, 2)"/>
					</MarkingLabelRef>
				</RFF>
			</NAD.SF>
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
			</LIN>
			<PIA>
				<SuppliersArticleNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'SA'], 2, 1)"/>
				</SuppliersArticleNum>
			</PIA>
			<xsl:for-each select="QTY">
			<QTY>
				<QtyAvailable>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 2)"/>
				</QtyAvailable>
				<QtyOrdered>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '21'], 1, 2)"/>
				</QtyOrdered>
			</QTY>
			</xsl:for-each>
			<GIN>
				<BatchNumber>
					<xsl:value-of select="edi:getElement(GIN[Field[1] = 'BX'], 2)"/>
				</BatchNumber>
			</GIN>
			<FTX>
				<Note>
					<xsl:value-of select="edi:getSubElement(FTX[Field[1] = 'Z01'], 4, 1)"/>
				</Note>
				<Note2>
					<xsl:value-of select="edi:getSubElement(FTX[Field[1] = 'Z03'], 4, 1)"/>
				</Note2>
			</FTX>
			<RFF>
				<BatchLotNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'BT'], 1, 2)"/>
				</BatchLotNum>
				<BatchNumFinal>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ZBT'], 1, 2)"/>
				</BatchNumFinal>
			</RFF>
		</Items>
	</xsl:template>
</xsl:stylesheet>
