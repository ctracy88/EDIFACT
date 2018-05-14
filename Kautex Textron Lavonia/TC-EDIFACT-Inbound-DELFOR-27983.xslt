<?xml version="1.0"?>
<!--
	Map to turn a Delphi Vega Edifact D97A Delfor into a Generic XML version
		
	Input: Delphi Vega Edifact D97A DELFOR
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

			<xsl:variable name="supplier" select="NAD[Field[1] = 'SU']"/>
			<xsl:variable name="shipfrom" select="NAD[Field[1] = 'SF']"/>
			<xsl:variable name="buyer" select="NAD[Field[1] = 'BY']"/>

			<Dates>
				<CreateDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '97'], 1, 2)"/>
				</CreateDate>
				<StartDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '158'], 1, 2)"/>
				</StartDate>
				<EndDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '159'], 1, 2)"/>
				</EndDate>
			</Dates>
			
			<Supplier>
				<Code>
					<xsl:value-of select="edi:getSubElement($supplier, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($supplier, 3, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement($supplier, 5, 1)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getSubElement($supplier, 6, 1)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($supplier, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getSubElement($supplier, 8, 1)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getSubElement($supplier, 9, 1)"/>
				</Country>
			</Supplier>
			<Buyer>
				<Code>
					<xsl:value-of select="edi:getSubElement($buyer, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($buyer, 3, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement($buyer, 5, 1)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getSubElement($buyer, 6, 1)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($buyer, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getSubElement($buyer, 8, 1)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getSubElement($buyer, 9, 1)"/>
				</Country>
			</Buyer>
			<ShipFrom>
				<Code>
					<xsl:value-of select="edi:getSubElement($shipfrom, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($shipfrom, 3, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement($shipfrom, 5, 1)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getSubElement($shipfrom, 6, 1)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($shipfrom, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getSubElement($shipfrom, 8, 1)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getSubElement($shipfrom, 9, 1)"/>
				</Country>
			</ShipFrom>
			
			
			<xsl:for-each select="UNS/NAD[Field[1] = 'ST']">
				<xsl:call-template name="processShipTo">
					<xsl:with-param name="ShipTo" select="."/>
				</xsl:call-template>
			</xsl:for-each>

		</Plan>

	</xsl:template>

	<!--
		Process the lines assigned to a given ShipTo.
	-->
	<xsl:template name="processShipTo">
		<xsl:param name="ShipTo"/>

		<ShipTo>
			<Code>
				<xsl:value-of select="edi:getSubElement(., 2, 1)"/>
			</Code>
			<Name>
				<xsl:value-of select="edi:getSubElement(., 3, 1)"/>
			</Name>
			<Address>
				<xsl:value-of select="edi:getSubElement(., 5, 1)"/>
			</Address>
			<City>
				<xsl:value-of select="edi:getSubElement(., 6, 1)"/>
			</City>
			<State>
				<xsl:value-of select="edi:getSubElement(., 7, 1)"/>
			</State>
			<ZipCode>
				<xsl:value-of select="edi:getSubElement(., 8, 1)"/>
			</ZipCode>
			<Country>
				<xsl:value-of select="edi:getSubElement(., 9, 1)"/>
			</Country>
			<ContactName>
					<xsl:value-of select="edi:getElement(CTA, 2)"/>
			</ContactName>
			<ContactPhone>
					<xsl:value-of select="edi:getSubElement(CTA/COM, 1, 1)"/>
			</ContactPhone>
		
		
			<xsl:apply-templates select="LIN">
				<xsl:with-param name="ShipTo" select="$ShipTo"/>
			</xsl:apply-templates>
		
		</ShipTo>
		
	</xsl:template>

	<xsl:template match="LIN">
		<xsl:param name="ShipTo"/>

		<Line>

			<!-- Odette specifes that the part number is defined by the buyer -->
			<!--
			<xsl:if test="edi:getSubElement(., 3, 2) != 'IN'">
				<mapper:logError>
					Consignment line (LIN segment) contains unsupported item qualifier: <xsl:value-of select="edi:getSubElement(., 3, 2)"/>
				</mapper:logError>
			</xsl:if>
-->		
			<ItemInfo>
				<LineNum>
					<xsl:value-of select="edi:getElement(., 1)"/>
				</LineNum>
				<BuyersPartNum>
					<xsl:value-of select="edi:getSubElement(., 3, 1)"/>
				</BuyersPartNum>
				<ItemPONum>
						<xsl:value-of select="edi:getSubElement(PIA, 2, 1)"/>
				</ItemPONum>
				<EngineeringChangeCode>
					<xsl:value-of select="edi:getSubElement(PIA, 3, 1)"/>
				</EngineeringChangeCode>
				<VendorPartNum>
					<xsl:value-of select="edi:getSubElement(PIA, 3, 1)"/>
				</VendorPartNum>
				<Description>
					<xsl:value-of select="edi:getSubElement(IMD, 3, 4)"/>
				</Description>
				<TransferOwnerCode>
					<xsl:value-of select="edi:getSubElement(LOC[Field[1] = '16'], 2, 1)"/>
				</TransferOwnerCode>
				<DeliveryCode>
					<xsl:value-of select="edi:getSubElement(LOC[Field[1] = '83'], 2, 1)"/>
				</DeliveryCode>
				<ItemNote>
					<xsl:value-of select="edi:getSubElement(FTX, 4, 1)"/>
				</ItemNote>
				<ItemContactName>
					<xsl:value-of select="edi:getSubElement(CTA, 2, 2)"/>
				</ItemContactName>
				<ProjectCode>
					<xsl:value-of select="edi:getSubElement(RFF, 1, 2)"/>
				</ProjectCode>
				
				<xsl:for-each select="QTY">
							
					<Quantity>
						<DiscreteQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 2)"/>
						</DiscreteQty>
						<DiscreteQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 3)"/>
						</DiscreteQtyUOM>
						<RawQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '3'], 1, 2)"/>
						</RawQty>
						<RawQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '3'], 1, 3)"/>
						</RawQtyUOM>
						<ReceivedQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '48'], 1, 2)"/>
						</ReceivedQty>
						<ReceivedQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '48'], 1, 3)"/>
						</ReceivedQtyUOM>
						<CumulativeQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '70'], 1, 2)"/>
						</CumulativeQty>
						<CumulativeQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '70'], 1, 3)"/>
						</CumulativeQtyUOM>
						<PrevCumulativeQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '79'], 1, 2)"/>
						</PrevCumulativeQty>
						<PrevCumulativeQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '79'], 1, 3)"/>
						</PrevCumulativeQtyUOM>
						<PeriodQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '135'], 1, 2)"/>
						</PeriodQty>
						<PeriodQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '135'], 1, 3)"/>
						</PeriodQtyUOM>
						<ReceiptDate>
							<xsl:value-of select="edi:getSubElement(self::node()/DTM[Field[1]/Field[1] = '50'], 1, 2)"/>
						</ReceiptDate>
						<CumulativeStartDate>
							<xsl:value-of select="edi:getSubElement(self::node()/DTM[Field[1]/Field[1] = '51'], 1, 2)"/>
						</CumulativeStartDate>
						<CumulativeEndDate>
							<xsl:value-of select="edi:getSubElement(self::node()/DTM[Field[1]/Field[1] = '52'], 1, 2)"/>
						</CumulativeEndDate>
						<ScheduleCondition>
							<StatusIndicator>
								<xsl:value-of select="edi:getElement(self::node()/SCC, 1)"/>
							</StatusIndicator>
							<Frequency>
								<xsl:value-of select="edi:getSubElement(self::node()/SCC, 3, 1)"/>
							</Frequency>
							<DespatchPattern>
								<xsl:value-of select="edi:getSubElement(self::node()/SCC, 3, 2)"/>
							</DespatchPattern>
							<ScheduleDates>
								<DeliverDate>
									<xsl:value-of select="edi:getSubElement(self::node()/SCC/DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
								</DeliverDate>
								<ShipmentDate>
									<xsl:value-of select="edi:getSubElement(self::node()/SCC/DTM[Field[1]/Field[1] = '10'], 1, 2)"/>
								</ShipmentDate>
								<PeriodStartDate>
									<xsl:value-of select="edi:getSubElement(self::node()/SCC/DTM[Field[1]/Field[1] = '194'], 1, 2)"/>
								</PeriodStartDate>
								<PeriodStopDate>
									<xsl:value-of select="edi:getSubElement(self::node()/SCC/DTM[Field[1]/Field[1] = '206'], 1, 2)"/>
								</PeriodStopDate>
							</ScheduleDates>
						</ScheduleCondition>
						<RefNum>
							<ShipperNum>
								<xsl:value-of select="edi:getSubElement(self::node()/RFF, 1, 2)"/>
							</ShipperNum>
						</RefNum>
					</Quantity>
				</xsl:for-each>
			</ItemInfo>

		</Line>

	</xsl:template>

</xsl:stylesheet>
