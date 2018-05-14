<?xml version="1.0"?>
<!--
	Map to turn a General Motors Edifact D97A DELJIT into TC XML
		
	Input: General Motors Edifact D97A DELJIT
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
		<ShipSchedule>
			<xsl:attribute name="number">
				<xsl:value-of select="edi:getElement(., 1)"/>
			</xsl:attribute>
			<xsl:attribute name="version">1</xsl:attribute>
			<xsl:attribute name="type">Plan</xsl:attribute>
			<Type>
				<xsl:value-of select="edi:getSubElement(BGM, 1, 1)"/>
			</Type>
			<DocNum>
				<xsl:value-of select="edi:getElement(BGM, 2)"/>
			</DocNum>
			<Purpose>
				<xsl:value-of select="edi:getElement(BGM, 3)"/>
			</Purpose>
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
			</BatchReferences>
			<BGM>
				<DocMsgID>
					<xsl:value-of select="edi:getSubElement(BGM, 1, 4)"/>
				</DocMsgID>
				<DocNum>
					<xsl:value-of select="edi:getElement(BGM, 2)"/>
				</DocNum>
				<Purpose>
					<xsl:value-of select="edi:getElement(BGM, 3)"/>
				</Purpose>
			</BGM>
			<DTM>
				<DocDate>
					<xsl:value-of select="substring(edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2),1,8)"/>
				</DocDate>
				<DocTime>
					<xsl:value-of select="substring(edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2),9,4)"/>
				</DocTime>
			</DTM>
			<RFF>
				<PONum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
				</PONum>
				<PromotionNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'PD'], 1, 2)"/>
				</PromotionNum>
				<UltimateCustOrderNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'UO'], 1, 2)"/>
				</UltimateCustOrderNum>
				<Suffix>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AJY'], 1, 2)"/>
				</Suffix>
				<TransportRoute>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AEM'], 1, 2)"/>
				</TransportRoute>
				<MutuallyDefinedRefNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ZZZ'], 1, 2)"/>
				</MutuallyDefinedRefNum>
				<DTM>
					<UltimateCustOrderDate>
						<xsl:value-of select="substring(edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '4'], 1, 2),1,8)"/>
					</UltimateCustOrderDate>
				</DTM>
			</RFF>
			<NAD.FW>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'FW'], 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'FW'], 2, 3)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'FW'], 4, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'FW'], 5, 1)"/>
				</Address>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'FW'], 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'FW'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'FW'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'FW'], 8)"/>
				</Zip>
			</NAD.FW>
			<NAD.SI>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SI'], 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SI'], 2, 3)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SI'], 4, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SI'], 5, 1)"/>
				</Address>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SI'], 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SI'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SI'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SI'], 8)"/>
				</Zip>
			</NAD.SI>
			<NAD.ST>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'ST'], 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'ST'], 2, 3)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'ST'], 4, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'ST'], 5, 1)"/>
				</Address>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'ST'], 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'ST'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'ST'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'ST'], 8)"/>
				</Zip>
			</NAD.ST>
			<NAD.SU>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 2, 3)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 4, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 5, 1)"/>
				</Address>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 8)"/>
				</Zip>
			</NAD.SU>
			<NAD.UD>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'UD'], 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'UD'], 2, 3)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'UD'], 4, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'UD'], 5, 1)"/>
				</Address>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'UD'], 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'UD'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'UD'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'UD'], 8)"/>
				</Zip>
			</NAD.UD>
			<NAD.WD>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'WD'], 2, 1)"/>
				</Code>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'WD'], 2, 3)"/>
				</CodeType>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'WD'], 4, 1)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'WD'], 5, 1)"/>
				</Address>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'WD'], 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'WD'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'WD'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'WD'], 8)"/>
				</Zip>
			</NAD.WD>
			<FTX>
				<xsl:for-each select="FTX">
					<Note><xsl:value-of select="edi:getSubElement(., 4, 1)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 2)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 3)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 4)"/></Note>
					<Note><xsl:value-of select="edi:getSubElement(., 4, 5)"/></Note>
				</xsl:for-each>
			</FTX>
			<xsl:for-each select="SEQ">
			<SEQ>
				<StatusIndicator>
					<xsl:value-of select="edi:getElement(self::node(), 1)"/>
				</StatusIndicator>
				<PAC>
					<PackagingLevelCode>
						<xsl:value-of select="edi:getSubElement(PAC, 2, 1)"/>
					</PackagingLevelCode>
					<xsl:for-each select="SEQ/PAC/PCI">
					<PCI>
						<ShippingMarks>
							<xsl:value-of select="edi:getElement(self::node(), 2)"/>
						</ShippingMarks>
					</PCI>
					</xsl:for-each>
				</PAC>
				<LIN>
					<LineNum>
						<xsl:value-of select="edi:getElement(LIN, 1)"/>
					</LineNum>
					<BuyersItemNum>
						<xsl:value-of select="edi:getSubElement(LIN[Field[3]/Field[2] = 'IN'], 3, 1)"/>
					</BuyersItemNum>
					<PIA>
						<CatalogNum>
							<xsl:value-of select="edi:getSubElement(LIN/PIA[Field[2]/Field[2] = 'MP'], 2, 1)"/>
						</CatalogNum>
						<SupplierPartNum>
							<xsl:value-of select="edi:getSubElement(LIN/PIA[Field[3]/Field[2] = 'SA'], 3, 1)"/>
						</SupplierPartNum>
						<UltimateCustArticleNum>
							<xsl:value-of select="edi:getSubElement(LIN/PIA[Field[4]/Field[2] = 'UA'], 4, 1)"/>
						</UltimateCustArticleNum>
					</PIA>
					<IMD>
						<Description>
							<xsl:value-of select="edi:getSubElement(LIN/IMD, 3, 4)"/>
						</Description>
					</IMD>
					<FTX>
						<ItemNote>
							<xsl:value-of select="edi:getSubElement(LIN/FTX[Field[1] = 'AAI'], 4, 1)"/>
						</ItemNote>
					</FTX>
					<RFF>
						<HazardousGoodsClassNum>
							<xsl:value-of select="edi:getSubElement(LIN/RFF[Field[1]/Field[1] = 'NA'], 1, 2)"/>
						</HazardousGoodsClassNum>
					</RFF>
					<LOC>
						<AdditionalInternalDestination>
							<xsl:value-of select="edi:getSubElement(LIN/LOC[Field[1]/Field[1] = '159'], 2, 1)"/>
						</AdditionalInternalDestination>
					</LOC>
					<xsl:for-each select="LIN/QTY">
					<QTY>
						<DiscreteQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 2)"/>
						</DiscreteQty>
						<DiscreteQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 3)"/>
						</DiscreteQtyUOM>
						<SCC>
							<DeliveryPlanStatusIndicator>
								<xsl:value-of select="edi:getElement(SCC, 1)"/>
							</DeliveryPlanStatusIndicator>
						</SCC>
						<DTM>
							<DeliveryDate>
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
							</DeliveryDate>
							<ShipNotLaterThanDate>
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '38'], 1, 2)"/>
							</ShipNotLaterThanDate>
							<ReceivedDate>
								<xsl:value-of select="substring(edi:getSubElement(DTM[Field[1]/Field[1] = '310'], 1, 2),1,8)"/>
							</ReceivedDate>						
						</DTM>
					</QTY>
					</xsl:for-each>
				</LIN>
			</SEQ>
			</xsl:for-each>
		</ShipSchedule>
	</xsl:template>
</xsl:stylesheet>