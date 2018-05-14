<?xml version="1.0"?>
<!--
	Map to turn a Cummins Edifact D97A Delfor into a Generic XML version
		
	Input: Cummins Edifact D97A DELFOR
	Output: XML
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: June 29, 2016
	
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
			<RFF>
				<LetterOfCreditNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'LC'], 1, 2)"/>
				</LetterOfCreditNum>
				<ImportLicenseNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'IP'], 1, 2)"/>
				</ImportLicenseNum>
				<ImportLicenseDate>
					<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '125'], 1, 2)"/>
				</ImportLicenseDate>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</DocDate>
			</RFF>
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
				</NAD.ST>
				<NAD.BY>
					<Code>
						<xsl:value-of select="edi:getSubElement(GIS/NAD[Field[1] = 'BY'], 2, 1)"/>
					</Code>
					<Name>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'BY'], 4)"/>
					</Name>
					<Address>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'BY'], 5)"/>
					</Address>
					<City>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'BY'], 6)"/>
					</City>
					<State>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'BY'], 7)"/>
					</State>
					<Zip>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'BY'], 8)"/>
					</Zip>
					<Country>
						<xsl:value-of select="edi:getElement(GIS/NAD[Field[1] = 'BY'], 9)"/>
					</Country>
					<CodeType>
						<xsl:value-of select="edi:getSubElement(GIS/NAD[Field[1] = 'BY'], 2, 3)"/>
					</CodeType>
				</NAD.BY>
				<Line>
				<xsl:for-each select="GIS/LIN">
				<LIN>
					<BuyersItemNum>
						<xsl:value-of select="edi:getSubElement(self::node(), 3, 1)"/>
					</BuyersItemNum>
					<LineNum>
						<xsl:value-of select="edi:getElement(self::node(), 1)"/>
					</LineNum>
					<PIA>
						<InternalProductGroupCode>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/PIA, 2, 1)"/>
						</InternalProductGroupCode>
						<RecordKeepingYear>
							<xsl:value-of select="edi:getSubElement(GIS/LIN/PIA, 3, 1)"/>
						</RecordKeepingYear>
					</PIA>
					<xsl:for-each select="IMD">
					<IMD>
						<Description>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1] = 'F'], 3, 4)"/>
						</Description>
						<VendorPartNum>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1] = 'F'], 3, 5)"/>
						</VendorPartNum>
					</IMD>
					</xsl:for-each>
					<LOC>
						<DeliveryLocation>
							<xsl:value-of select="edi:getElement(LOC[Field[1] = '7'], 2)"/>
						</DeliveryLocation>
					</LOC>
					<xsl:for-each select="RFF">
					<RFF>
						<OrderNum>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = 'ON'], 1, 2)"/>
						</OrderNum>
						<POLineNum>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = 'ON'], 1, 3)"/>
						</POLineNum>
						<DrawingNum>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = 'AAL'], 1, 2)"/>
						</DrawingNum>
						<DrawingListNum>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = 'AEQ'], 1, 2)"/>
						</DrawingListNum>
					</RFF>
					</xsl:for-each>
					<xsl:for-each select="QTY">
					<QTY>
						<CumulativeQtyReq>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '3'], 1, 2)"/>
						</CumulativeQtyReq>
						<CumulativeQtyReqUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '3'], 1, 3)"/>
						</CumulativeQtyReqUOM>
						<LastRecQty>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '48'], 1, 2)"/>
						</LastRecQty>
						<LastRecQtyUOM>
							<xsl:value-of select="edi:getSubElement(self::node()[Field[1]/Field[1] = '48'], 1, 3)"/>
						</LastRecQtyUOM>
						<LastRecQtyShipperNum>
							<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'SI'], 1, 2)"/>
						</LastRecQtyShipperNum>
						<LastRecQtyDate>
							<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '50'], 1, 2)"/>
						</LastRecQtyDate>
						<CumulativeStartDate>
							<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '51'], 1, 2)"/>
						</CumulativeStartDate>
						<CumulativeEndDate>
							<xsl:value-of select="edi:getSubElement(RFF/DTM[Field[1]/Field[1] = '52'], 1, 2)"/>
						</CumulativeEndDate>
					</QTY>
					</xsl:for-each>
					<xsl:for-each select="SCC">
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
							<SCC.DTM>
								<DeliveryDate>
									<xsl:value-of select="edi:getSubElement(self::node()/DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
								</DeliveryDate>
							</SCC.DTM>
							<SCC.RFF>
								<ReleaseNum>
									<xsl:value-of select="edi:getSubElement(self::node()/RFF[Field[1]/Field[1] = 'RE'], 1, 2)"/>
								</ReleaseNum>
							</SCC.RFF>
						</SCC.QTY>
						</xsl:for-each>
					</SCC>
					</xsl:for-each>
				</LIN>
				</xsl:for-each>
			</Line>
			</GIS>
		</Plan>
	</xsl:template>
</xsl:stylesheet>