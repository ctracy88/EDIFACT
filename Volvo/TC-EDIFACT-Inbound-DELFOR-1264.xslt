<?xml version="1.0"?>
<!--
	Map to turn a Volvo Edifact D96A Delfor into a Generic XML version
		
	Input: Volvo Edifact D96A DELFOR
	Output: XML
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: July 20, 2016
	
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
				Contact Mapping.
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
				<xsl:apply-templates select="/Document/UNB/UNH">
					<xsl:with-param name="envelope" select="/Document/UNB"/>
				</xsl:apply-templates>
			</Batch>
		</file:save>
	</xsl:template>


	<xsl:template match="UNH">
		<xsl:param name="envelope"/>
		<Plan>
			<xsl:attribute name="number">
				<xsl:value-of select="edi:getElement(., 1)"/>
			</xsl:attribute>
			<xsl:attribute name="version">1</xsl:attribute>
			<xsl:attribute name="type">Plan</xsl:attribute>
			<BatchReferences>
				<xsl:attribute name="test">
					<xsl:choose>
						<xsl:when test="edi:getElement($envelope, 11) = '1'">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>				
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
			<Dates>
				<CreateDate>
					<xsl:value-of select="substring(edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2),1,8)"/>
				</CreateDate>
				<StartDate>
					<xsl:value-of select="substring(edi:getSubElement(DTM[Field[1]/Field[1] = '157'], 1, 2),1,8)"/>
				</StartDate>
				<EndDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '36'], 1, 2)"/>
				</EndDate>
			</Dates>
			<Buyer>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'BY'], 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'BY'], 3)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'BY'], 5)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'BY'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'BY'], 7)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'BY'], 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'BY'], 9)"/>
				</Country>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'BY'], 2, 3)"/>
				</CodeType>
			</Buyer>
			<NAD.SE>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SE'], 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SE'], 3)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SE'], 5)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SE'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SE'], 7)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SE'], 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SE'], 9)"/>
				</Country>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SE'], 2, 3)"/>
				</CodeType>
			</NAD.SE>
			<xsl:for-each select="UNS/NAD">
			<ShipTo>
				<Code>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[1] = 'CN'], 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getElement(self::node()[Field[1] = 'CN'], 4)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getElement(self::node()[Field[1] = 'CN'], 5)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getElement(self::node()[Field[1] = 'CN'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(self::node()[Field[1] = 'CN'], 7)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement(self::node()[Field[1] = 'CN'], 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement(self::node()[Field[1] = 'CN'], 9)"/>
				</Country>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[1] = 'CN'], 2, 3)"/>
				</CodeType>
				<Line>
					<xsl:for-each select="LIN">
					<LIN>
						<BuyersItemNum>
							<xsl:value-of select="edi:getSubElement(self::node(), 3, 1)"/>
						</BuyersItemNum>
						<ActionCode>
							<xsl:value-of select="edi:getElement(self::node(), 2)"/>
						</ActionCode>
						<LOC>
							<PortOfDischarge>
								<xsl:value-of select="edi:getElement(LOC[Field[1] = '11'], 2)"/>
							</PortOfDischarge>
							<AdditionalDestination>
								<xsl:value-of select="edi:getElement(LOC[Field[1] = '159'], 2)"/>
							</AdditionalDestination>
						</LOC>
						<DTM>
							<CalcDate>
								<xsl:value-of select="substring(edi:getSubElement(DTM[Field[1]/Field[1] = '257'], 1, 2),1,8)"/>
							</CalcDate>
							<CumQtyStartDate>
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '51'], 1, 2)"/>
							</CumQtyStartDate>
						</DTM>
						<RFF>
							<OrderNum>
								<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
							</OrderNum>
							<PrevDelivInstructNum>
								<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AIF'], 1, 2)"/>
							</PrevDelivInstructNum>
						</RFF>
						<xsl:for-each select="QTY">
						<QTY>
							<CumulativeQtyRec>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '70'], 1, 2)"/>
							</CumulativeQtyRec>
							<DespatchQty>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '12'], 1, 2)"/>
							</DespatchQty>
							<QtyBalance>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '73'], 1, 2)"/>
							</QtyBalance>
							<DespatchAdviceNum>
								<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AAK'], 1, 2)"/>
							</DespatchAdviceNum>
							<DespatchAdviceNumDate>
								<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '171'], 1, 2)"/>
							</DespatchAdviceNumDate>
							<ReceivedQty>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '48'], 1, 2)"/>
							</ReceivedQty>
							<BackorderQty>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '83'], 1, 2)"/>
							</BackorderQty>
							<QtyDelivered>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '113'], 1, 2)"/>
							</QtyDelivered>
							<DeliveryDate>
									<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
							</DeliveryDate>
							<xsl:for-each select="SCC">
							<SCC>
								<StatusIndicator>
									<xsl:value-of select="edi:getElement(self::node(), 1)"/>
								</StatusIndicator>
							</SCC>
							</xsl:for-each>
						</QTY>
						</xsl:for-each>
					
					</LIN>
					</xsl:for-each>
				</Line>
				
			</ShipTo>
			</xsl:for-each>
		</Plan>
	</xsl:template>
</xsl:stylesheet>