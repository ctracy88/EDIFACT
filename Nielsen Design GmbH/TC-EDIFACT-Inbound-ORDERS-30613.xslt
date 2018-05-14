<?xml version="1.0"?>
<!--
	XSLT to transform an Edifact Purchase Order message into a Generix XML variation.
	
	Input: EDIFACT D93A/D96A/D97A ORDER.
	Output: Generic XML Order.
	
	Author: Pete Shelmerdine
	Version: 1.0
	Creation Date: 02-May-2006
	
	Last Modified Date: 02-May-2006
	Last Modified By: Pete Shelmerdine
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
				<ShipDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
				</ShipDate>
				<CancelDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '46'], 1, 2)"/>
				</CancelDate>
				<WarehouseShipDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '79'], 1, 2)"/>
				</WarehouseShipDate>
				<DocDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '137'], 1, 2)"/>
				</DocDate>
				<PostingDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '202'], 1, 2)"/>
				</PostingDate>
				<WarehouseCancelDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '383'], 1, 2)"/>
				</WarehouseCancelDate>
				<RevisedDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '558'], 1, 2)"/>
				</RevisedDate>
				<EarliestDeliveryDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
				</EarliestDeliveryDate>
				<LatestDeliveryDate>
					<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
				</LatestDeliveryDate>
			</DTM>
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
				<VendorNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'IA'], 1, 2)"/>
				</VendorNum>
				<PaymentRef>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'PQ'], 1, 2)"/>
				</PaymentRef>
				<ClassType>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'SZ'], 1, 2)"/>
				</ClassType>
				<Event>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ABO'], 1, 2)"/>
				</Event>
				<DivisionNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ACD'], 1, 2)"/>
				</DivisionNum>
				<Bank>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ACK'], 1, 2)"/>
				</Bank>
				<WMTWeek>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AIV'], 1, 2)"/>
				</WMTWeek>
				<DeptNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AMV'], 1, 2)"/>
				</DeptNum>
				<Season>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ASG'], 1, 2)"/>
				</Season>
				<QuoteID>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ASV'], 1, 2)"/>
				</QuoteID>
				<BusinessFormat>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AUB'], 1, 2)"/>
				</BusinessFormat>
				<OTB>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AUU'], 1, 2)"/>
				</OTB>
				<POType>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'CAW'], 1, 2)"/>
				</POType>
				<PromotionNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'PD'], 1, 2)"/>
				</PromotionNum>
				<AccountNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ADE'], 1, 2)"/>
				</AccountNum>
			</RFF>
			<!-- Start of NADs></!-->
			<xsl:variable name="beneficiary" select="NAD[Field[1] = 'BE']"/>
			<xsl:variable name="broker" select="NAD[Field[1] = 'CB']"/>
			<xsl:variable name="consolidator" select="NAD[Field[1] = 'CS']"/>
			<xsl:variable name="logistics" select="NAD[Field[1] = 'HE']"/>
			<xsl:variable name="creation" select="NAD[Field[1] = 'HI']"/>
			<xsl:variable name="creditoffice" select="NAD[Field[1] = 'IV']"/>
			<xsl:variable name="manufacturer" select="NAD[Field[1] = 'MF']"/>
			<xsl:variable name="ShipTo" select="NAD[Field[1] = 'DP']"/>
			<xsl:variable name="supplier" select="NAD[Field[1] = 'SU']"/>
			<xsl:variable name="BuyingParty" select="NAD[Field[1] = 'BY']"/>
			
			<BuyingParty>
				<Code>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 4, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($BuyingParty, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($BuyingParty, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($BuyingParty, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($BuyingParty, 9)"/>
				</Country>
					<RFF>
						<AccountNumber>
							<xsl:value-of select="edi:getSubElement($supplier/RFF[Field[1]/Field[1] = 'API'], 1, 2)"/>
						</AccountNumber>
					</RFF>
			</BuyingParty>

			<Broker>
				<Code>
					<xsl:value-of select="edi:getSubElement($broker, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($broker, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($broker, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($broker, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($broker, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($broker, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($broker, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($broker, 9)"/>
				</Country>
			</Broker>
			<Consolidator>
				<Code>
					<xsl:value-of select="edi:getSubElement($consolidator, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($consolidator, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($consolidator, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($consolidator, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($consolidator, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($consolidator, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($consolidator, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($consolidator, 9)"/>
				</Country>
			</Consolidator>
			<LogisticsOffice>
				<Code>
					<xsl:value-of select="edi:getSubElement($logistics, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($logistics, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($logistics, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($logistics, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($logistics, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($logistics, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($logistics, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($logistics, 9)"/>
				</Country>
				<LOC>
					<DestLocation>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '8'], 2, 4)"/>
					</DestLocation>
					<PortLoading>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '9'], 2, 4)"/>
					</PortLoading>
					<DischargePort>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '11'], 2, 4)"/>
					</DischargePort>
					<PlacePossession>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '16'], 2, 4)"/>
					</PlacePossession>
					<EntryPort>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '24'], 2, 4)"/>
					</EntryPort>
					<CountryOrigin>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '27'], 2, 1)"/>
					</CountryOrigin>
					<DestCountry>
						<xsl:value-of select="edi:getSubElement($logistics/LOC[Field[1] = '28'], 2, 1)"/>
					</DestCountry>
				</LOC>
			</LogisticsOffice>
			<CreationOffice>
				<Code>
					<xsl:value-of select="edi:getSubElement($creation, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($creation, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($creation, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($creation, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($creation, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($creation, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($creation, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($creation, 9)"/>
				</Country>
				<CTA>
					<OrderingBuyer>
						<xsl:value-of select="edi:getSubElement($creation/CTA[Field[1] = 'BJ'], 2, 2)"/>
					</OrderingBuyer>
					<ManagingBuyer>
						<xsl:value-of select="edi:getSubElement($creation/CTA[Field[1] = 'OC'], 2, 2)"/>
					</ManagingBuyer>
				</CTA>
			</CreationOffice>
			<CreditOffice>
				<Code>
					<xsl:value-of select="edi:getSubElement($creditoffice, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($creditoffice, 4, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($creditoffice, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($creditoffice, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($creditoffice, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($creditoffice, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($creditoffice, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($creditoffice, 9)"/>
				</Country>
					<RFF>
						<VATRegistration>
							<xsl:value-of select="edi:getSubElement($creditoffice/RFF[Field[1]/Field[1] = 'VA'], 1, 2)"/>
						</VATRegistration>
					</RFF>
			</CreditOffice>
			<Manufacturer>
				<Code>
					<xsl:value-of select="edi:getSubElement($manufacturer, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($manufacturer, 4, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($manufacturer, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($manufacturer, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($manufacturer, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($manufacturer, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($manufacturer, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($manufacturer, 9)"/>
				</Country>
			</Manufacturer>
			<ShipTo>
				<Code>
					<xsl:value-of select="edi:getSubElement($ShipTo, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($ShipTo, 4, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($ShipTo, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($ShipTo, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($ShipTo, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($ShipTo, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($ShipTo, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($ShipTo, 9)"/>
				</Country>
				<WarehouseNum>
					<xsl:value-of select="edi:getSubElement($ShipTo, 4, 1)"/>
				</WarehouseNum>
			</ShipTo>
			<Supplier>
				<Code>
					<xsl:value-of select="edi:getSubElement($supplier, 2, 1)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement($supplier, 4, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement($supplier, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement($supplier, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement($supplier, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement($supplier, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement($supplier, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement($supplier, 9)"/>
				</Country>
					<RFF>
						<AccountNumber>
							<xsl:value-of select="edi:getSubElement($supplier/RFF[Field[1]/Field[1] = 'API'], 1, 2)"/>
						</AccountNumber>
					</RFF>
			</Supplier>
			<!--END NADs -->	
			
			<CUX>
				<CurrencyType>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 1)"/>
				</CurrencyType>
				<Currency>
					<xsl:value-of select="edi:getSubElement(CUX, 1, 2)"/>
				</Currency>
				<DTM>
					<NegotiationDate>
						<xsl:value-of select="edi:getSubElement(CUX/DTM, 1, 2)"/>
					</NegotiationDate>
				</DTM>
			</CUX>
			<PAT>
				<TermsTypeQual>
					<xsl:value-of select="edi:getElement(PAT, 1)"/>
				</TermsTypeQual>
				<TermsDescriptionID>
					<xsl:value-of select="edi:getSubElement(PAT, 2, 1)"/>
				</TermsDescriptionID>
				<TermsResponCode>
					<xsl:value-of select="edi:getSubElement(PAT, 2, 3)"/>
				</TermsResponCode>
				<TermsDescription>
					<xsl:value-of select="edi:getSubElement(PAT, 2, 4)"/>
				</TermsDescription>
				<TermsTimeRefCode>
					<xsl:value-of select="edi:getSubElement(PAT, 3, 1)"/>
				</TermsTimeRefCode>
				<TermsPeriodTypeCode>
					<xsl:value-of select="edi:getSubElement(PAT, 3, 3)"/>
				</TermsPeriodTypeCode>
				<TermsNetDaysDue>
					<xsl:value-of select="edi:getSubElement(PAT, 3, 4)"/>
				</TermsNetDaysDue>
				<MOA>
				<TotalStoreCostFF>
					<xsl:value-of select="edi:getSubElement(PAT/MOA[Field[1]/Field[1] = '91'], 1, 2)"/>
				</TotalStoreCostFF>
				<TotalNetFirstCost>
					<xsl:value-of select="edi:getSubElement(PAT/MOA[Field[1]/Field[1] = '259'], 1, 2)"/>
				</TotalNetFirstCost>
				<TotalGrossMarginFF>
					<xsl:value-of select="edi:getSubElement(PAT/MOA[Field[1]/Field[1] = '464'], 1, 2)"/>
				</TotalGrossMarginFF>
			</MOA>
			</PAT>
			<TDT>
				<TransportStageCodeQual>
					<xsl:value-of select="edi:getElement(TDT, 1)"/>
				</TransportStageCodeQual>
				<TransportMeansCode>
					<xsl:value-of select="edi:getSubElement(TDT, 4, 1)"/>
				</TransportMeansCode>
				<TransportMeansDescription>
					<xsl:value-of select="edi:getSubElement(TDT, 4, 2)"/>
				</TransportMeansDescription>
			</TDT>
			<TOD>
				<DeliveryTransportTerms>
					<xsl:value-of select="edi:getSubElement(TOD, 3, 1)"/>
				</DeliveryTransportTerms>
			</TOD>
			
			<xsl:variable name="carton" select="PAC[Field[3]/Field[1] = 'CT']"/>
			<xsl:variable name="each" select="PAC[Field[3]/Field[1] = 'PA']"/>
			
			<QtyCartons>
				<Qty>
					<xsl:value-of select="edi:getElement($carton, 1)"/>
				</Qty>
				<MEA>
					<Weight>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[3]/Field[1] = 'KGM'], 3, 2)"/>
					</Weight>
					<Volume>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[3]/Field[1] = 'MTQ'], 3, 2)"/>
					</Volume>
				</MEA>
			</QtyCartons>
			<QtyEaches>
				<Qty>
					<xsl:value-of select="edi:getElement($each, 1)"/>
				</Qty>
			</QtyEaches>
			<ALC>
				<Type>
					<xsl:value-of select="edi:getElement(ALC, 1)"/>
				</Type>
			</ALC>
			
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
				<UPC>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'UP'], 3, 1)"/>
				</UPC>
				<PartNum>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'BH'], 3, 1)"/>
				</PartNum>
				<ServiceNumber>
					<xsl:value-of select="edi:getSubElement(self::node()[Field[3]/Field[2] = 'SRV'], 3, 1)"/>
				</ServiceNumber>
				<BuyersItemNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'IN'], 2, 1)"/>
				</BuyersItemNum>
				<UPC>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'UP'], 2, 1)"/>
				</UPC>
				<VendorItemNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'VN'], 2, 1)"/>
				</VendorItemNum>
				<VariantName>
					<xsl:value-of select="edi:getSubElement(IMD, 3, 4)"/>
				</VariantName>
				<VariantDescription>
					<xsl:value-of select="edi:getSubElement(IMD, 3, 5)"/>
				</VariantDescription>
			</LIN>
			<PIA>
				<BuyersItemNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[3]/Field[2] = 'BP'], 3, 1)"/>
				</BuyersItemNum>
				<SuppliersArticleNum>
					<xsl:value-of select="edi:getSubElement(PIA[Field[2]/Field[2] = 'SA'], 2, 1)"/>
				</SuppliersArticleNum>
			</PIA>
			<QTY>
				<QtyOrdered>
					<xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '47'], 1, 2)"/>
				</QtyOrdered>
			</QTY>
			<PRI>
				<Price>
					<xsl:value-of select="edi:getSubElement(PRI[Field[1]/Field[1] = 'AAA'], 1, 2)"/>
				</Price>
			</PRI>
			<PCD>
				<DutyPercent>
					<xsl:value-of select="edi:getSubElement(PCD, 1, 2)"/>
				</DutyPercent>
			</PCD>
			<MOA>
				<DutyValue>
					<xsl:value-of select="edi:getSubElement(MOA, 1, 2)"/>
				</DutyValue>
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
			<RFF>
				<PackageNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'CW'], 1, 2)"/>
				</PackageNum>
				<OrderNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
				</OrderNumber>
				<FileLineID>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'FI'], 1, 2)"/>
				</FileLineID>
				<AssortmentID>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'LI'], 1, 2)"/>
				</AssortmentID>
				<OrderNumber>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ON'], 1, 2)"/>
				</OrderNumber>
				<VendorStock>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'VP'], 1, 2)"/>
				</VendorStock>
				<TariffNum>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ABD'], 1, 2)"/>
				</TariffNum>
				<PackDescription>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AES'], 1, 2)"/>
				</PackDescription>
				<ProductDescription1>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ALX'], 1, 2)"/>
				</ProductDescription1>
				<Subclass>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'ANE'], 1, 2)"/>
				</Subclass>
				<ClassifierType>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AOS'], 1, 2)"/>
				</ClassifierType>
				<AssortmentIndicator>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AST'], 1, 2)"/>
				</AssortmentIndicator>
				<QuotaCategory>
					<xsl:value-of select="edi:getSubElement(RFF[Field[1]/Field[1] = 'AWH'], 1, 2)"/>
				</QuotaCategory>
				<MOA>
					<DutyAmt>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '55'], 1, 2)"/>
					</DutyAmt>
					<StoreCostFF>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '64'], 1, 2)"/>
					</StoreCostFF>
					<FirstCost>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '128'], 1, 2)"/>
					</FirstCost>
					<StoreCost>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '187'], 1, 2)"/>
					</StoreCost>
					<DefectAllowPercent>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '260'], 1, 2)"/>
					</DefectAllowPercent>
					<Retail>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '402'], 1, 2)"/>
					</Retail>
					<NetFirstCost>
						<xsl:value-of select="edi:getSubElement(RFF/MOA[Field[1]/Field[1] = '465'], 1, 2)"/>
					</NetFirstCost>
				</MOA>
			</RFF>
			<PAC>
				<PackQty>
					<xsl:value-of select="edi:getElement(PAC, 1)"/>
				</PackQty>
				<PackageType>
					<xsl:value-of select="edi:getSubElement(PAC, 4, 2)"/>
				</PackageType>
				<MEA>
					<Height>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'HT'], 3, 2)"/>
					</Height>
					<HeightUOM>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'HT'], 3, 1)"/>
					</HeightUOM>
					<Length>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2]= 'LN'], 3, 2)"/>
					</Length>
					<LengthUOM>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'LN'], 3, 1)"/>
					</LengthUOM>
					<Width>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'WD'], 3, 2)"/>
					</Width>
					<WidthUOM>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'WD'], 3, 1)"/>
					</WidthUOM>
					<Volume>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'ABJ'], 3, 2)"/>
					</Volume>
					<VolumeUOM>
						<xsl:value-of select="edi:getSubElement(PAC/MEA[Field[2] = 'ABJ'], 3, 1)"/>
					</VolumeUOM>
				</MEA>
				<QTY>
					<QtyOrdered>
						<xsl:value-of select="edi:getSubElement(PAC/QTY[Field[1]/Field[1] = '21'], 1, 2)"/>
					</QtyOrdered>
					<TotalQtyPerLine>
						<xsl:value-of select="edi:getSubElement(PAC/QTY[Field[1]/Field[1] = '142'], 1, 2)"/>
					</TotalQtyPerLine>
				</QTY>
			</PAC>
			<NAD>
				<Code>
					<xsl:value-of select="edi:getElement(NAD, 2)"/>
				</Code>
				<Name>
					<xsl:value-of select="edi:getSubElement(NAD, 3, 1)"/>
				</Name>
				<Address1>
					<xsl:value-of select="edi:getSubElement(NAD, 5, 1)"/>
				</Address1>
				<Address2>
					<xsl:value-of select="edi:getSubElement(NAD, 5, 2)"/>
				</Address2>
				<City>
					<xsl:value-of select="edi:getElement(NAD, 6)"/>
				</City>
				<State>
					<xsl:value-of select="edi:getSubElement(NAD, 7, 1)"/>
				</State>
				<ZipCode>
					<xsl:value-of select="edi:getElement(NAD, 8)"/>
				</ZipCode>
				<Country>
					<xsl:value-of select="edi:getElement(NAD, 9)"/>
				</Country>
			</NAD>
			<xsl:for-each select="ALC">
			<ALC>
				<AllowChargeCode>
					<xsl:value-of select="edi:getElement(., 1)"/>
				</AllowChargeCode>
				<SpecialServicesCode>
					<xsl:value-of select="edi:getSubElement(., 5, 1)"/>
				</SpecialServicesCode>
				<PCD>
					<DefectAllowPercent>
						<xsl:value-of select="edi:getSubElement(PCD[Field[1]/Field[1] = '1'], 1, 2)"/>
					</DefectAllowPercent>
					<MarkUpPercent>
						<xsl:value-of select="edi:getSubElement(PCD[Field[1]/Field[1] = '9'], 1, 2)"/>
					</MarkUpPercent>
					<MarkUpPercentFF>
						<xsl:value-of select="edi:getSubElement(PCD[Field[1]/Field[1] = 'ZZZ'], 1, 2)"/>
					</MarkUpPercentFF>
				</PCD>
			</ALC>
			</xsl:for-each>
			<EQD>
				<Type>
					<xsl:value-of select="edi:getElement(EQD, 1)"/>
				</Type>
				<FTX>
					<xsl:for-each select="EQD/FTX">
						<Note><xsl:value-of select="edi:getSubElement(., 4, 1)"/></Note>
						<Note><xsl:value-of select="edi:getSubElement(., 4, 2)"/></Note>
						<Note><xsl:value-of select="edi:getSubElement(., 4, 3)"/></Note>
						<Note><xsl:value-of select="edi:getSubElement(., 4, 4)"/></Note>
						<Note><xsl:value-of select="edi:getSubElement(., 4, 5)"/></Note>
					</xsl:for-each>
				</FTX>
			</EQD>
			
		</Items>
	</xsl:template>
	<!--
		Process an order line.
	-->
	<xsl:template match="OLDLIN">
	
		<!--
			LIN element 2 (Action Coded)...
			
      1 Added
            This line item is added to the referenced message.
      2 Deleted
            This line item is deleted from the referenced message.
      3 Changed
            This line item is changed in the referenced message.
      4 No action
            This line item is not affected by the actual message.
      5 Accepted without amendment
            This line item is entirely accepted by the seller.
      6 Accepted with amendment
            This line item is accepted but amended by the seller.
      7 Not accepted
            This line item is not accepted by the seller.
      8 Schedule only
            Self explanatory.
      9 Amendments
            Self explanatory.
      10 Not found
            This line item is not found in the referenced message.
      11 Not amended
            This line is not amended by the buyer.
      12 Line item numbers changed
            Self explanatory.
      13 Buyer has deducted amount
            Buyer has deducted amount from payment.
      14 Buyer claims against invoice
            Buyer has a claim against an outstanding invoice.
      15 Charge back by seller
            Factor has been requested to charge back the outstanding
            item.
      16 Seller will issue credit note
            Seller agrees to issue a credit note.
      17 Terms changed for new terms
            New settlement terms have been agreed.
      18 Abide outcome of negotiations
            Factor agrees to abide by the outcome of negotiations
            between seller and buyer.
      19 Seller rejects dispute
            Seller does not accept validity of dispute.
      20 Settlement
            The reported situation is settled.
      21 No delivery
            Code indicating that no delivery will be required.
      22 Call-off delivery
            A request for delivery of a particular quantity of goods
            to be delivered on a particular date (or within a
            particular period).
      23 Proposed amendment
            A code used to indicate an amendment suggested by the
            sender.
      24 Accepted with amendment, no confirmation required
            Accepted with changes which require no confirmation.
		-->
	
		<OrderLine>
			<xsl:attribute name="action">
				<xsl:variable name="code" select="Field[2]"/>
				<xsl:choose>
					<xsl:when test="$code = '1'">Add</xsl:when>
					<xsl:when test="$code = '2'">Delete</xsl:when>
					<xsl:when test="$code = '3'">Change</xsl:when>
					<xsl:when test="string-length($code) = 0">Add</xsl:when>
					<xsl:otherwise>
						<mapper:logError>
							Unsupported action code in LIN: <xsl:value-of select="$code"/>
						</mapper:logError>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		
			<!-- Product info can come in from LIN or PIA -->
			<Product>
				<LineNumber><xsl:value-of select="position()"/></LineNumber>
				<EanCode> <!-- EAN (13 digits) or UPC (12 digits) code -->
          <xsl:choose>
            <xsl:when test="Field[3]/Field[2] = 'EN'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'EN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[2] = 'UP'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'UP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[2]/Field[4] = 9]/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'EN']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'UP']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[3]/Field[4] = 9]/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'EN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'UP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[4]/Field[4] = 9]/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'EN']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'UP']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[5]/Field[4] = 9]/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'EN']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'UP']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[4] = 9">
              <xsl:value-of select="PIA[Field[6]/Field[4] = 9]/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'EN'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'EN']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'UP'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'UP']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[4] = 9">
              <xsl:value-of select="Field[3]/Field[1]"/>
            </xsl:when>
          </xsl:choose>
        </EanCode>
				<SuppliersCode>
          <xsl:choose>
            <xsl:when test="Field[3]/Field[2] = 'SA'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'SA']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[2]/Field[4] = 91]/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'SA']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[3]/Field[4] = 91]/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'SA']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'SA']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[4]/Field[4] = 91]/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[5]/Field[4] = 91]/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'SA']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'SA'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'SA']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[4] = 91">
              <xsl:value-of select="PIA[Field[6]/Field[4] = 91]/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[4] = 91">
              <xsl:value-of select="Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'IB'">
              <!-- ISBN so put it in Suppliers and Customers code -->
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'IB']/Field[2]/Field[1]"/>
            </xsl:when>
          </xsl:choose>
        </SuppliersCode>
				<CustomersCode>
          <xsl:choose>
            <xsl:when test="Field[3]/Field[2] = 'IN'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'IN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[2] = 'BP'">
              <xsl:value-of select="self::node()[Field[3]/Field[2] = 'BP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[2]/Field[4] = 92]/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'IN']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'BP']/Field[2]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[3]/Field[4] = 92]/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'IN']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[3]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[3]/Field[2] = 'BP']/Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[4]/Field[4] = 92]/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'IN']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[4]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[4]/Field[2] = 'BP']/Field[4]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[5]/Field[4] = 92]/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'IN']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[5]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[5]/Field[2] = 'BP']/Field[5]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[4] = 92">
              <xsl:value-of select="PIA[Field[6]/Field[4] = 92]/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'IN'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'IN']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[6]/Field[2] = 'BP'">
              <xsl:value-of select="PIA[Field[6]/Field[2] = 'BP']/Field[6]/Field[1]"/>
            </xsl:when>
            <xsl:when test="Field[3]/Field[4] = 92">
              <xsl:value-of select="Field[3]/Field[1]"/>
            </xsl:when>
            <xsl:when test="PIA/Field[2]/Field[2] = 'IB'">
              <!--  ISBN so put it in Suppliers and Customers code -->
              <xsl:value-of select="PIA[Field[2]/Field[2] = 'IB']/Field[2]/Field[1]"/>
            </xsl:when>
          </xsl:choose>
        </CustomersCode>
				<PalletCode/>
				<OtherCode><xsl:value-of select="self::node()[Field[3]/Field[2] = 'ZZZ']/Field[3]/Field[1]"/></OtherCode>
				<Name><xsl:value-of select="concat(edi:getSubElement(IMD, 3, 4), edi:getSubElement(IMD, 3, 5))"/></Name>
				<FreeText/>
			</Product>

			<Quantity>
				<AmountPerUnit><xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '59'], 1, 2)"/></AmountPerUnit>
				<Amount><xsl:value-of select="edi:getSubElement(QTY[Field[1]/Field[1] = '21'], 1, 2)"/></Amount>
				<MeasureIndicator><xsl:value-of select="edi:getSubElement(QTY, 1, 3)"/></MeasureIndicator>
			</Quantity>
			
			<DeliverBy>
				<Date> <!-- YYYY-MM-DD -->
					<xsl:if test="DTM[Field[1]/Field[1] = '64'] and DTM[Field[1]/Field[3] = '204']"> <!-- Earliest Delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '63'] and DTM[Field[1]/Field[3] = '204']"> <!-- Latest Delivery date -->
						<Latest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '64']"> <!-- Earliest Delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '63']"> <!-- Latest Delivery date -->
						<Latest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '2']"> <!-- Requested delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
						<Latest>
							<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '2'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
				</Date>
				<Time> <!-- HH:MM:SS -->
					<xsl:if test="DTM[Field[1]/Field[1] = '64'] and DTM[Field[1]/Field[3] = '204']"> <!-- Earliest Delivery date -->
						<Earliest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="HH:mm:ss">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '64'], 1, 2)"/>
							</date:reformat>						
						</Earliest>
					</xsl:if>
					<xsl:if test="DTM[Field[1]/Field[1] = '63'] and DTM[Field[1]/Field[3] = '204']"> <!-- Latest Delivery date -->
						<Latest>
							<date:reformat curFormat="yyyyMMddHHmmss" newFormat="HH:mm:ss">
								<xsl:value-of select="edi:getSubElement(DTM[Field[1]/Field[1] = '63'], 1, 2)"/>
							</date:reformat>						
						</Latest>
					</xsl:if>
				</Time>			
				<BookingReferenceNumber></BookingReferenceNumber>
				<FreeText></FreeText>
			</DeliverBy>

			<xsl:if test="PRI">
				<Price currency="GBP" rate="1.0">
					<NetUnitPrice> <!-- with discounts applied, but not multiplied by quantity -->
						<xsl:value-of select="format-number(edi:getSubElement(PRI, 1, 2), '0.0000')"/>
					</NetUnitPrice>
					<LineDiscount>0.0000</LineDiscount>
				</Price>
			</xsl:if>

		</OrderLine>
	
	</xsl:template>

</xsl:stylesheet>
