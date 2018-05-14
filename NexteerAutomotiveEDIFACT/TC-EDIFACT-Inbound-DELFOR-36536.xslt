<?xml version="1.0"?>
<!--
	Map to turn a Summit Polymers Edifact D97A Delfor into a Generic XML version
		
	Input: Summit Polymers Edifact D97A DELFOR
	Output: XML
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: March 19, 2017
	
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
			<DTM>
				<CreateDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</CreateDate>
				<StartDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '158'], 1, 2)"/>
				</StartDate>
				<EndDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '159'], 1, 2)"/>
				</EndDate>
			</DTM>
			<NAD.MI>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'MI'], 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'MI'], 3)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'MI'], 5)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'MI'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'MI'], 7)"/>
				</State>
				<Zip>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'MI'], 8)"/>
				</Zip>
				<Country>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'MI'], 9)"/>
				</Country>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'MI'], 2, 3)"/>
				</CodeType>
				<CTA>
					<MaterialIssuerContactType>
						<xsl:value-of select="edi:getSubElement(NAD/CTA, 1, 1)"/>
					</MaterialIssuerContactType>
					<MaterialIssuerContactName>
						<xsl:value-of select="edi:getSubElement(NAD/CTA, 2, 2)"/>
					</MaterialIssuerContactName>
					<COM>
						<MaterialIssuerContactPhone>
							<xsl:value-of select="edi:getSubElement(NAD/CTA/COM[Field[2]/Field[1] = 'TE'], 1, 1)"/>						
						</MaterialIssuerContactPhone>
						<MaterialIssuerContactFax>
							<xsl:value-of select="edi:getSubElement(NAD/CTA/COM[Field[2]/Field[1] = 'FX'], 1, 1)"/>						
						</MaterialIssuerContactFax>
						<MaterialIssuerContactEmail>
							<xsl:value-of select="edi:getSubElement(NAD/CTA/COM[Field[2]/Field[1] = 'EM'], 1, 1)"/>						
						</MaterialIssuerContactEmail>
					</COM>
				</CTA>
			</NAD.MI>
			<NAD.SU>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 4)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 5)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 7)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SU'], 9)"/>
				</Country>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SU'], 2, 3)"/>
				</CodeType>
			</NAD.SU>
			<NAD.SF>
				<Code>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SF'], 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SF'], 4)"/>
				</Name>
				<Address>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SF'], 5)"/>
				</Address>
				<City>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SF'], 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SF'], 7)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SF'], 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement(NAD[Field[1] = 'SF'], 9)"/>
				</Country>
				<CodeType>
					<xsl:value-of select="edi:getSubElement(NAD[Field[1] = 'SF'], 2, 3)"/>
				</CodeType>
			</NAD.SF>
			<GIS>
				<ProcessingCode>
					<xsl:value-of select="edi:getElement(GIS, 1)"/>
				</ProcessingCode>
				<NAD.ST>
					<Code>
						<xsl:value-of select="edi:getSubElement(GIS/NAD[Field[1] = 'ST'], 2, 1)"/>
					</Code>
					<Name>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'ST'], 4)"/>
					</Name>
					<Address>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'ST'], 5)"/>
					</Address>
					<City>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'ST'], 6)"/>
					</City>
					<State>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'ST'], 7)"/>
					</State>
					<Zip>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'ST'], 8)"/>
					</Zip>
					<Country>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'ST'], 9)"/>
					</Country>
					<CodeType>
						<xsl:value-of select="edi:getSubElement(GIS/NAD[Field[1] = 'ST'], 2, 3)"/>
					</CodeType>
					<CTA>
						<ContactName>
							<xsl:value-of select="edi:getSubElement(GIS/NAD/CTA[Field[1] = 'IC'], 2, 2)"/>
						</ContactName>
					</CTA>
					<COM>
						<ContactPhone>
							<xsl:value-of select="edi:getSubElement(GIS/NAD/COM[Field[2]/Field[1] = 'TE'], 1, 1)"/>
						</ContactPhone>
					</COM>
				</NAD.ST>
				<Line>
				<LIN>
					<BuyersItemNum>
						<xsl:value-of select="edi:getSubElement(GIS/LIN, 3, 1)"/>
					</BuyersItemNum>
					<IMD>
						<Description>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/IMD, 3, 4)"/>
						</Description>
					</IMD>
					<LOC>
						<DeliveryLocation>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/LOC[Field[1] = '11'], 2, 1)"/>
						</DeliveryLocation>
						<DeliveryLocationDescription>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/LOC[Field[1] = '11'], 2, 4)"/>
						</DeliveryLocationDescription>
						<AdditionalInternalDestination>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/LOC[Field[1] = '159'], 2, 1)"/>
						</AdditionalInternalDestination>
					</LOC>
					<FTX>
						<ItemNote>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/FTX[Field[1] = 'AAI'], 4, 1)"/>
						</ItemNote>
					</FTX>
					<RFF>
						<OrderNum>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
						</OrderNum>
						<POLineNum>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/RFF[Field[1]/Field[1] = 'ON'], 1, 3)"/>
						</POLineNum>

					</RFF>
					<DTM>
						<DeliveryScheduleDate>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
						</DeliveryScheduleDate>
						<RFF>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/DTM/RFF[Field[1]/Field[1] = 'AIF'], 1, 2)"/>
						</RFF>
					</DTM>
					<xsl:for-each select="GIS/LIN/QTY">
					<QTY>
						<CumulativeQtyRec>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '79'], 1, 2)"/>
						</CumulativeQtyRec>
						<CumulativeQtyRecUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '79'], 1, 3)"/>
						</CumulativeQtyRecUOM>
						<CumulativeStartDate>
							<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '51'], 1, 2)"/>
						</CumulativeStartDate>
						<CumulativeEndDate>
							<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '52'], 1, 2)"/>
						</CumulativeEndDate>
						<LastRecQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '3'], 1, 2)"/>
						</LastRecQty>
						<LastRecQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '3'], 1, 3)"/>
						</LastRecQtyUOM>
						<LastRecQtyDate>
							<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '51'], 1, 2)"/>
						</LastRecQtyDate>
						<CumulativeQtyActuallyReceivedEndDate>
							<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '52'], 1, 2)"/>
						</CumulativeQtyActuallyReceivedEndDate>
						<LastRecQtyShipperNum>
							<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'SI'], 1, 2)"/>
						</LastRecQtyShipperNum>
						<DespatchDate>
							<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '11'], 1, 2)"/>
						</DespatchDate>
					</QTY>
					</xsl:for-each>
					<xsl:for-each select="GIS/LIN/SCC">
					<SCC>
						<StatusIndicator>
							<xsl:value-of select="edi:getElement(., 1)"/>
						</StatusIndicator>
						<Frequency>
							<xsl:value-of select="edi:getElement(., 3)"/>
						</Frequency>
						<xsl:for-each select="QTY">
						<SCC.QTY>
							<DiscreteQty>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 2)"/>
							</DiscreteQty>
							<DiscreteQtyUOM>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '1'], 1, 3)"/>
							</DiscreteQtyUOM>
							<CumulativeQty>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '83'], 1, 2)"/>
							</CumulativeQty>
							<CumulativeQtyUOM>
								<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '83'], 1, 3)"/>
							</CumulativeQtyUOM>
							<SCC.DTM>
								<DespatchDate>
									<xsl:value-of select="edi:getSubElement(self::node()/DTM[Field[1]/Field[1] = '10'], 1, 2)"/>
								</DespatchDate>
								<DeliveryDate>
									<xsl:value-of select="edi:getSubElement(self::node()/DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
								</DeliveryDate>
							</SCC.DTM>
						</SCC.QTY>
							<SCC.PAC>
								<PackLevel>
									<xsl:value-of select="edi:getElement(., 2)"/>
								</PackLevel>
								<TypeOfPackage>
									<xsl:value-of select="edi:getElement(., 3)"/>
								</TypeOfPackage>
								<SSC.PAC.QTY>
									<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '52'], 1, 2)"/>
								</SSC.PAC.QTY>
							</SCC.PAC>
						</xsl:for-each>
					</SCC>
					</xsl:for-each>
				</LIN>
				</Line>
			</GIS>
		</Plan>
	</xsl:template>
</xsl:stylesheet>