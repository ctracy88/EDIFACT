<?xml version="1.0"?>
<!--
	Input: MX CSV..
	Output: Generic XML Invoice.
	
	Author: Roy Hocknull
	Version: 1.0
	Creation Date: 
	
	Last Modified Date: 27-APR-2012
	Last Modified By: Roy Hocknull
-->
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"				
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
                xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension"
                xmlns:flat="com.css.base.xml.xslt.ext.flat.XsltParsedFFVExtension"
                xmlns:csv="com.css.base.xml.xslt.ext.flat.XsltCsvLoaderExtension"
                xmlns:mapper="com.api.tx.MapperEngine"
                xmlns:barcode="com.api.tx.ext.CheckDigit"
                xmlns:local="http://www.atlasproducts.com/local_function"
                xmlns:func="http://exslt.org/functions"
                extension-element-prefixes="date math flat csv mapper str barcode local func">
                
	<xsl:import href="/home/matrix/interconnect/res/mapper/xslt/generic/dcl.xslt"/>
                
  <xsl:output method="xml"/>

	<xsl:param name="Profile"/>
	<xsl:param name="HubInfo"/>

  <xsl:template match="/Document">
		<xsl:variable name="profile" select="document($Profile)/Profile"/>
		<xsl:variable name="hubs" select="document($HubInfo)/Hubs"/>
                <xsl:variable name="AccountCode" select="HDR/Field[4]"/>

                <xsl:variable name="hubID">
			<xsl:choose>
				<xsl:when test="HDR/Field[4] = 'P0086'">Taulia</xsl:when>
				<xsl:when test="HDR/Field[4] = 'H0628'">Hendersons-Untdi</xsl:when>
				<xsl:otherwise>
					<mapper:logError>
					Unknown Account Code <xsl:value-of select="$AccountCode"/>
					</mapper:logError>
				</xsl:otherwise>
			</xsl:choose>
                </xsl:variable>

		<xsl:variable name="partner" select="$profile/Partners/Partner[@hubID = $hubID]"/>
		<xsl:if test="not($partner)">
			<mapper:logError>
				Cannot locate partner with internal ID: <xsl:value-of select="$hubID"/>
			</mapper:logError>
		</xsl:if>
		
		<xsl:variable name="hub" select="$hubs/Hub[@id = $hubID]/Envelope[Document/@id = 'INVOICE'][@test = $partner/@testing]"/>
		<xsl:if test="not($hub)">
			<mapper:logError>
				Cannot locate hub with internal ID: <xsl:value-of select="$hubID"/>
			</mapper:logError>
		</xsl:if>

		<Batch>
			<xsl:apply-templates select="HDR">
				<xsl:with-param name="profile" select="$profile"/>
				<xsl:with-param name="partner" select="$partner"/>
				<xsl:with-param name="hub" select="$hub"/>
				<xsl:with-param name="hubID" select="$hubID"/>
			</xsl:apply-templates>
		</Batch>		
	</xsl:template>
	
	
	<xsl:template match="HDR">
		<xsl:param name="profile"/>
		<xsl:param name="partner"/>
		<xsl:param name="hub"/>
		<xsl:param name="hubID"/>
		
		<mapper:logMessage>
			HUB = <xsl:value-of select="$hubID"/>
		</mapper:logMessage>
		
		<mapper:logDetail>
			Invoice number: <b><xsl:value-of select="Field[14]"/></b>, Date: <xsl:value-of select="Field[15]"/>
		</mapper:logDetail>

		<mapper:logMessage>
			Invoice number: <xsl:value-of select="Field[14]"/>
		</mapper:logMessage>
				
<!--
		<xsl:variable name="duplicateCheck">
			<xsl:value-of select="mapper:lookupDCL('PreviousInvoices', $partner/SupplierIDForCustomer, 'Number', Field[14], 'Date')"/>
		</xsl:variable>					
		<xsl:if test="string-length($duplicateCheck) &gt; 0">
			<mapper:logWarning>
				Invoice number <xsl:value-of select="Field[14]"/>, was previously sent on <xsl:value-of select="$duplicateCheck"/>
			</mapper:logWarning>
		</xsl:if>
		
-->
		<!-- Do not create duplicates -->
<!--		<xsl:if test="string-length($duplicateCheck) = 0">-->
			<Invoice type="New">
				<xsl:attribute name="currency"><xsl:value-of select="Field[28]"/></xsl:attribute>
				<xsl:attribute name="credit">
					<!-- HDR Field 3... 2 = credit, 1 = invoice -->
					<xsl:choose>
						<xsl:when test="Field[3] = '2'">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				
				<xsl:variable name="SenderANA" select="$partner/SenderEnvEan"/>
				<xsl:variable name="SenderName" select="$partner/SenderEnvName"/>
				<xsl:variable name="ReceiverANA" select="$hub/@ean"/>
				<xsl:variable name="ReceiverName" select="$hub/@name"/>

				<BatchReferences>
					<xsl:attribute name="test">
						<xsl:choose>
							<xsl:when test="$partner/@testing = 'true'">true</xsl:when>
							<xsl:otherwise>false</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<Number><xsl:value-of select="0"/></Number>
					<Version><xsl:value-of select="0"/></Version>
					<Date><xsl:value-of select="date:insert('yyyy-MM-dd')"/></Date>				
					<SenderCode><xsl:value-of select="$SenderANA"/></SenderCode>
					<SenderName><xsl:value-of select="$SenderName"/></SenderName>
					<ReceiverCode><xsl:value-of select="$ReceiverANA"/></ReceiverCode>
					<ReceiverName><xsl:value-of select="$ReceiverName"/></ReceiverName>				
					<BatchRef><xsl:value-of select="0"/></BatchRef>
				</BatchReferences>

				<Supplier>
					<EanCode><xsl:value-of select="$partner/SenderDocEan"/></EanCode>
					<SuppliersCode/>
					<CustomersCode><xsl:value-of select="$partner/CustomersIDForSupplier"/></CustomersCode>
					<Name><xsl:value-of select="$profile/Address/@name"/></Name>
					<Address>
						<Title><xsl:value-of select="$profile/Address/@a1"/></Title>
						<Street><xsl:value-of select="$profile/Address/@a2"/></Street>
						<Town><xsl:value-of select="$profile/Address/@a3"/></Town>
						<City><xsl:value-of select="$profile/Address/@a4"/></City>
						<PostCode><xsl:value-of select="$profile/Address/@pc"/></PostCode>
						<Country><xsl:value-of select="$profile/Address/@cc"/></Country>
					</Address>
                                        <xsl:choose>
                                          <!-- numeric VAT number for some customers -->
                                          <xsl:when test="$hubID = 'Sainsburys'">
                                            <VatNumber><xsl:value-of select="$profile/Address/@vat2"/></VatNumber>                                            
                                          </xsl:when>
                                          <xsl:when test="$hubID = 'TescoUK'">
                                            <VatNumber><xsl:value-of select="$profile/Address/@vat2"/></VatNumber>                                            
                                          </xsl:when>
                                          <xsl:otherwise>
                                            <VatNumber><xsl:value-of select="$profile/Address/@vat"/></VatNumber>                                            
                                          </xsl:otherwise>
                                        </xsl:choose>
				</Supplier>

				<xsl:choose>
					<!-- Different musgraves have different addresses -->
					<xsl:when test="starts-with($hubID, 'Musgrave')">
						<Customer>
							<EanCode><xsl:value-of select="$hub/../Address[@type = 'IV']/@ean"/></EanCode>
							<SuppliersCode><xsl:value-of select="$partner/SupplierIDForCustomer"/></SuppliersCode>
							<CustomersCode/>
							<Name><xsl:value-of select="$hub/../Address[@type = 'IV']/@name"/></Name>
							<Address>
								<Title><xsl:value-of select="$hub/../Address[@type = 'IV']/@a1"/></Title>
								<Street><xsl:value-of select="$hub/../Address[@type = 'IV']/@a2"/></Street>
								<Town><xsl:value-of select="$hub/../Address[@type = 'IV']/@a3"/></Town>
								<City><xsl:value-of select="$hub/../Address[@type = 'IV']/@a4"/></City>
								<PostCode><xsl:value-of select="$hub/../Address[@type = 'IV']/@pc"/></PostCode>
							</Address>
							<VatNumber><xsl:value-of select="$hub/../Address[@type = 'IV']/@vat"/></VatNumber>
						</Customer>
					</xsl:when>
					<xsl:otherwise>
						<Customer>
							<EanCode><xsl:value-of select="$ReceiverANA"/></EanCode>
							<SuppliersCode><xsl:value-of select="$partner/SupplierIDForCustomer"/></SuppliersCode>
							<CustomersCode/>
							<Name><xsl:value-of select="$ReceiverName"/></Name>
							<Address>
								<Title><xsl:value-of select="$hub/../Address/@a1"/></Title>
								<Street><xsl:value-of select="$hub/../Address/@a2"/></Street>
								<Town><xsl:value-of select="$hub/../Address/@a3"/></Town>
								<City><xsl:value-of select="$hub/../Address/@a4"/></City>
								<PostCode><xsl:value-of select="$hub/../Address/@pc"/></PostCode>
							</Address>
							<VatNumber><xsl:value-of select="$hub/../Address/@vat"/></VatNumber>

							<xsl:apply-templates select="TXT"/>
						</Customer>
					</xsl:otherwise>
				</xsl:choose>


				<xsl:variable name="SupplierLocationCode">
						<xsl:value-of select="Field[5]"/>
				</xsl:variable>		
				
				<xsl:variable name="EanLocationCode" select="Field[6]"/>
				
				<xsl:variable name="CustomerLocationCode">
					<xsl:choose>
						<xsl:when test="starts-with($hubID, 'Dunnes')">
							<!-- Do nothing -->
						</xsl:when>
						<xsl:when test="starts-with($hubID, 'Tesco')">
							<xsl:value-of select="local:Get-Customer-Store-Code(Field[6])"/>
						</xsl:when>
						<xsl:when test="starts-with($hubID, 'Sainsburys')">
                                                    <!-- digits 10 through 12 of the ANA, prepended with a 0 -->
                                                    <xsl:value-of select="concat('0', substring($EanLocationCode, 10, 3))"/>
						</xsl:when>
						<xsl:when test="$hubID = 'Hendersons-Untdi' and starts-with(Field[6], '00000')">
							<xsl:value-of select="str:last(Field[6], 5)"/> <!-- 5 digit store code in EAN - field 6 -->
						</xsl:when>
						<xsl:when test="$hubID = 'Hendersons-Untdi' and starts-with(Field[6], '0000')">
							<xsl:value-of select="str:last(Field[6], 5)"/> <!-- 5 digit store code in EAN - field 6 -->
						</xsl:when>
						<xsl:when test="$hubID = 'Hendersons-Untdi' and string-length(Field[6]) = 5">
							<xsl:value-of select="Field[6]"/> <!-- 5 digit store code in EAN - field 6 -->
						</xsl:when>
						<xsl:when test="$hubID = 'Costcutter' and Field[6] = 'BT40 1TG'">
							<xsl:value-of select="'26017'"/> <!-- Insert proper code -->
						</xsl:when>
						<xsl:when test="$hubID = 'Costcutter' and starts-with(Field[6], '00000')">
							<xsl:value-of select="str:last(Field[6], 5)"/> <!-- 5 digit store code in EAN -->
						</xsl:when>
						<xsl:when test="$hubID = 'Costcutter' and string-length(Field[6]) = 5">
							<xsl:value-of select="Field[6]"/> <!-- 5 digit store code in EAN - field 6 -->
						</xsl:when>
						<xsl:when test="$hubID = 'JJHaslett-Untdi' and starts-with(Field[6], '00000')">
							<xsl:value-of select="str:last(Field[6], 5)"/> <!-- 5 digit store code in EAN -->
						</xsl:when>
						<xsl:when test="$hubID = 'JJHaslett-Untdi' and starts-with(Field[6], '0000')">
							<xsl:value-of select="str:last(Field[6], 5)"/> <!-- 5 digit store code in EAN -->
						</xsl:when>
						<xsl:when test="$hubID = 'JJHaslett-Untdi' and string-length(Field[6]) = 5">
							<xsl:value-of select="Field[6]"/> <!-- 5 digit store code in EAN - field 6 -->
						</xsl:when>
						<xsl:when test="string-length(Field[7]) &gt; 0">
							<xsl:value-of select="Field[7]"/>
						</xsl:when>
						<xsl:when test="$hubID = 'ASDA'">
							<xsl:value-of select="Field[7]"/> <!-- 4 digit store code is here -->
						</xsl:when>
						<xsl:otherwise> <!-- do a lookup -->
<!--							<xsl:value-of select="$locations/Document/Record[Field[4] = $SupplierLocationCode]/Field[1]"/>-->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:if test="string-length($CustomerLocationCode) = 0 and string-length($EanLocationCode) = 0">
					<mapper:logError>
						No EAN or Customer location code provided for <xsl:value-of select="concat(Field[8], ' ', Field[11])"/>
					</mapper:logError>
				</xsl:if>

				<xsl:if test="contains($CustomerLocationCode, ' ')">
					<mapper:logError>
						The store/depot code looks suspicious <xsl:value-of select="$CustomerLocationCode"/>
					</mapper:logError>
				</xsl:if>
				
				<DeliverTo>
					<EanCode><xsl:value-of select="$EanLocationCode"/></EanCode>
					<SuppliersCode><xsl:value-of select="$SupplierLocationCode"/></SuppliersCode>
					<CustomersCode><xsl:value-of select="$CustomerLocationCode"/></CustomersCode>
					<Name><xsl:value-of select="concat(Field[8], ' ', Field[11])"/></Name>
					<Address>
						<Title><xsl:value-of select="Field[9]"/></Title>
						<Street><xsl:value-of select="Field[10]"/></Street>
						<Town><xsl:value-of select="Field[11]"/></Town>
						<City><xsl:value-of select="Field[12]"/></City>
						<PostCode>
							<!-- They sometimes put a shop code in here which is poo -->
							<xsl:choose>
								<xsl:when test="not(math:isNum(Field[13]))"><xsl:value-of select="Field[13]"/></xsl:when>
							</xsl:choose>							
						</PostCode>
						<Country><xsl:value-of select="'GB'"/></Country>
					</Address>
				</DeliverTo>
						
				<xsl:variable name="invoiceDate">
					<xsl:call-template name="convertDate">
						<xsl:with-param name="fromDate" select="Field[15]"/>
					</xsl:call-template>
				</xsl:variable>
<!--			
				<mapper:setDCL name="PreviousInvoices" keyTag="Number">
					Section = <xsl:value-of select="$partner/SupplierIDForCustomer"/>
					Number = <xsl:value-of select="Field[14]"/>
					InvDate = <xsl:value-of select="$invoiceDate"/>
					Date = <xsl:value-of select="date:insert('yyyy-MM-dd')"/>
				</mapper:setDCL>
-->				
				<InvoiceNumber><xsl:value-of select="Field[14]"/></InvoiceNumber>
				<InvoiceDate><xsl:value-of select="$invoiceDate"/></InvoiceDate>
				<InvoiceExpiresDate>
					<xsl:choose>
						<xsl:when test="string-length(Field[26]) &gt; 0">
							<xsl:call-template name="convertDate">					
								<xsl:with-param name="fromDate" select="Field[26]"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="convertDate">					
								<xsl:with-param name="fromDate" select="Field[15]"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</InvoiceExpiresDate>
				<TaxPointDate>
					<xsl:call-template name="convertDate">
						<xsl:with-param name="fromDate" select="Field[15]"/>
					</xsl:call-template>
				</TaxPointDate>
				
				<DeliveryDate>
					<xsl:call-template name="convertDate">
						<xsl:with-param name="fromDate" select="Field[24]"/>
					</xsl:call-template>
				</DeliveryDate>

				<ContractNumber><xsl:value-of select="'CG34'"/></ContractNumber> <!-- This is a requirement for Compass -->
				
				<xsl:if test="string-length(Field[25]) &gt; 0 or string-length(Field[26]) &gt; 0 or string-length(Field[27]) &gt; 0">
					<SettlementDiscount>
						<Terms><xsl:value-of select="Field[25]"/></Terms>
						<Percentage><xsl:value-of select="format-number(str:remove(Field[27], '%'), '0.00')"/></Percentage>
						<ExpiresDate>
							<xsl:call-template name="convertDate">
								<xsl:with-param name="fromDate" select="Field[26]"/>
							</xsl:call-template>
						</ExpiresDate>
					</SettlementDiscount>
				</xsl:if>
				
                                <xsl:variable name="orderNumber" select="Field[17]"/>
                                
				<OrderNumber>
					<Customers><xsl:value-of select="$orderNumber"/></Customers>
					<Suppliers><xsl:value-of select="Field[19]"/></Suppliers>
				</OrderNumber>

				<OrderDate>
					<Customers>
						<xsl:call-template name="convertDate">
							<xsl:with-param name="fromDate" select="Field[18]"/>
						</xsl:call-template>
					</Customers>
					<Suppliers>
						<xsl:call-template name="convertDate">
							<xsl:with-param name="fromDate" select="Field[18]"/>
						</xsl:call-template>
					</Suppliers>
				</OrderDate>
				
				<DeliveryNoteNumber>
					<xsl:choose>
						<!-- Dunnes want the PO number in the RFF+AAK for some reason -->
<!--						<xsl:when test="starts-with($hubID, 'Dunnes')"><xsl:value-of select="Field[17]"/></xsl:when> -->
                                                <!-- Now they don't the mentally challenged potato eating bare back riding inbreds -->
						<xsl:when test="starts-with($hubID, 'Dunnes')"><xsl:value-of select="Field[21]"/></xsl:when>
                                                <!-- JS want the order number in here for consolidation purposes -->
                                                <xsl:when test="$hubID = 'Sainsburys'"><xsl:value-of select="Field[17]"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="Field[21]"/></xsl:otherwise>
					</xsl:choose>					
				</DeliveryNoteNumber>
				<DeliveryNoteDate>
					<xsl:call-template name="convertDate">
						<xsl:with-param name="fromDate" select="Field[22]"/>
					</xsl:call-template>
				</DeliveryNoteDate>
				<DeliveryProofNumber>
					<xsl:choose>
						<xsl:when test="string-length(Field[23]) &gt; 0">
							<xsl:value-of select="Field[23]"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="Field[21]"/> <!-- See if we can get away with the delivery note number -->
						</xsl:otherwise>
					</xsl:choose>
				</DeliveryProofNumber>

				<!-- Process the lines -->
				<xsl:apply-templates select="LNE">
					<xsl:with-param name="hubID" select="$hubID"/>
				</xsl:apply-templates>
				
				<mapper:setVar name="gross">0</mapper:setVar>
				<mapper:setVar name="discount">0</mapper:setVar>
				<mapper:setVar name="surcharge">0</mapper:setVar>
				<mapper:setVar name="settlement">0</mapper:setVar>
				<mapper:setVar name="total2">0</mapper:setVar>
				<mapper:setVar name="total3">0</mapper:setVar>
				<mapper:setVar name="vat">0</mapper:setVar>
				<mapper:setVar name="total4">0</mapper:setVar>
				<mapper:setVar name="total5">0</mapper:setVar>
				
				<!-- Process the VAT summaries -->
				<xsl:apply-templates select="VAT"/>
				
				<!-- Invoice summary -->
				<InvoiceSummary>
					<Total1><mapper:getVar name="gross"/></Total1> <!-- LVLT Excluding VAT, discounts and charges -->
					<Discount><mapper:getVar name="discount"/></Discount> <!-- QYDT or VLDT -->
					<Surcharge><mapper:getVar name="surcharge"/></Surcharge> <!-- SURT -->
					<Subsidy>0.00</Subsidy> <!-- TSUB -->
					<Total2><mapper:getVar name="total2"/></Total2> <!-- EVLT Excluding VAT and settlement discount, including charges and discounts -->
					<SettlementDiscount><mapper:getVar name="settlement"/></SettlementDiscount> <!-- SEDT -->
					<Total3><mapper:getVar name="total3"/></Total3> <!-- ASDT Excluding VAT, including settlement discount, charges and discounts -->
					<VatAmount><mapper:getVar name="vat"/></VatAmount> <!-- TVAT -->
					<Total4><mapper:getVar name="total4"/></Total4> <!-- TPSE Excluding settlement discount, including VAT, charges and discounts -->
					<Total5><mapper:getVar name="total5"/></Total5> <!-- TPSI Including settlement discount, VAT, charges and discounts -->		
				</InvoiceSummary>
				
				<mapper:logDetail>
					Invoice Gross: <xsl:value-of select="mapper:getVar('total5')"/>
					VAT Total: <xsl:value-of select="mapper:getVar('vat')"/>
				</mapper:logDetail>						
				
			</Invoice>		
<!--		</xsl:if>-->
		
	</xsl:template>


	<!--
		Process a Vat Summary
	-->
	<xsl:template match="VAT">
	
		<xsl:variable name="gross" select="math:toNum(Field[6])"/>
		<xsl:variable name="discount" select="math:toNum(Field[7])"/>
		<xsl:variable name="surcharge" select="math:toNum(Field[8])"/>
		<xsl:variable name="settlement" select="math:toNum(Field[9])"/>
		<xsl:variable name="total2" select="$gross - $discount + $surcharge"/>
		<xsl:variable name="total3" select="$total2 - $settlement"/>
		<xsl:variable name="vat" select="math:toNum(Field[10])"/>
		<xsl:variable name="total4" select="$total2 + $vat"/>
		<xsl:variable name="total5" select="$total3 + $vat"/>

		<mapper:addToVar name="gross"><xsl:value-of select="$gross"/></mapper:addToVar>
		<mapper:addToVar name="discount"><xsl:value-of select="$discount"/></mapper:addToVar>
		<mapper:addToVar name="surcharge"><xsl:value-of select="$surcharge"/></mapper:addToVar>
		<mapper:addToVar name="settlement"><xsl:value-of select="$settlement"/></mapper:addToVar>
		<mapper:addToVar name="total2"><xsl:value-of select="$total2"/></mapper:addToVar>
		<mapper:addToVar name="total3"><xsl:value-of select="$total3"/></mapper:addToVar>
		<mapper:addToVar name="vat"><xsl:value-of select="$vat"/></mapper:addToVar>
		<mapper:addToVar name="total4"><xsl:value-of select="$total4"/></mapper:addToVar>
		<mapper:addToVar name="total5"><xsl:value-of select="$total5"/></mapper:addToVar>
	
		<VatSummary>
			<VatCode><xsl:value-of select="Field[3]"/></VatCode>
			<VatPercentage><xsl:value-of select="Field[4]"/></VatPercentage> <!-- VATP -->
			<ApplicableLines><xsl:value-of select="Field[5]"/></ApplicableLines> <!-- NRIL  Number of lines this applies to -->
			<Total1><xsl:value-of select="$gross"/></Total1> <!-- LVLA  Excluding VAT, discounts and charges -->
			<Discount><xsl:value-of select="$discount"/></Discount> <!-- QYDA or VLDA -->
			<Surcharge><xsl:value-of select="$surcharge"/></Surcharge> <!-- SURA -->
			<Subsidy>0.00</Subsidy> <!-- SSUB -->
			<Total2><xsl:value-of select="$total2"/></Total2> <!-- EVLA Excluding VAT and settlement discount, including charges and discounts -->
			<SettlementDiscount><xsl:value-of select="$settlement"/></SettlementDiscount> <!-- SEDA -->
			<Total3><xsl:value-of select="$total3"/></Total3> <!-- ASDA Excluding VAT, including settlement discount, charges and discounts -->
			<VatAmount><xsl:value-of select="$vat"/></VatAmount> <!-- VATA after settlement discount and charges has been applied to the value -->
			<Total4><xsl:value-of select="$total4"/></Total4> <!-- APSE Excluding settlement discount, including VAT, charges and discounts -->
			<Total5><xsl:value-of select="$total5"/></Total5> <!-- APSI Including settlement discount, VAT, charges and discounts -->
		</VatSummary>	
	</xsl:template>



	<!--
		Process an invoice line.
	-->
	<xsl:template match="LNE">
		<xsl:param name="hubID"/>
<!--		<xsl:param name="products"/>-->
		
		<xsl:variable name="suppliersCode" select="Field[3]"/>
		
		<InvoiceLine>
			<xsl:attribute name="credited">
				<!-- HDR Field 3... 2 = credit, 1 = invoice -->
				<xsl:choose>
					<xsl:when test="../Field[3] = '2'">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<Product>
				<LineNumber><xsl:value-of select="Field[2]"/></LineNumber>
				<EanCode>
					<xsl:choose>
						<xsl:when test="$hubID = 'Morrisons-Eancom'">
							<xsl:value-of select="concat('0',Field[4])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="Field[4]"/>
						</xsl:otherwise>
					</xsl:choose>
				</EanCode>
				<SuppliersCode><xsl:value-of select="$suppliersCode"/></SuppliersCode>
				<CustomersCode><xsl:value-of select="''"/></CustomersCode>
				<InnerBarcode/>
				<Name>
					<xsl:choose>
						<!-- Regular description field -->
						<xsl:when test="string-length(Field[8]) &gt; 0 or string-length(Field[9]) &gt; 0">
							<xsl:value-of select="str:replace(concat(Field[8], Field[9]), '%', 'pc')"/>
						</xsl:when>
						<!-- Product code in description rather than nuffin -->
						<xsl:when test="string-length($suppliersCode) &gt; 0">
							<xsl:value-of select="$suppliersCode"/>
						</xsl:when>
						<xsl:when test="string-length(Field[4]) &gt; 0">
							<xsl:value-of select="Field[4]"/>
						</xsl:when>
						<xsl:otherwise>**********</xsl:otherwise>
					</xsl:choose>
				</Name>
			</Product>
			
			<Quantity>
				<AmountPerUnit><xsl:value-of select="Field[10]"/></AmountPerUnit> <!-- number of items which make up one unit (per inner box) -->
				<Amount><xsl:value-of select="Field[11]"/></Amount> <!-- number of units delivered (number of AmountPerUnits) -->
				<MeasureIndicator>
					<xsl:choose>
						<xsl:when test="string-length(Field[13]) &gt; 0">
							<xsl:value-of select="Field[13]"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'Each'"/>
						</xsl:otherwise>
					</xsl:choose>
				</MeasureIndicator>
			</Quantity>
			
			<Price currency="GBP" rate="1.0">
				<UnitPrice><xsl:value-of select="math:toNum(Field[14])"/></UnitPrice> <!-- exclusive of discounts (gross) -->
				<LineDiscount>0.00</LineDiscount>
				<LineSubsidy>0.00</LineSubsidy>
				<LineTotal><xsl:value-of select="math:toNum(Field[15])"/></LineTotal>
			</Price>
			
			<Vat>
				<Code><xsl:value-of select="Field[16]"/></Code>
				<Percentage><xsl:value-of select="math:toNum(Field[17])"/></Percentage>
				<LineVat><xsl:value-of select="math:toNum(Field[18])"/></LineVat>
			</Vat>		
		</InvoiceLine>
	</xsl:template>
	
	
	<xsl:template name="convertDate">
		<xsl:param name="fromDate"/>
		
		<xsl:choose>
			<xsl:when test="str:contains($fromDate, '/') and string-length($fromDate) = 8">
				<date:reformat curFormat="dd/MM/yy" newFormat="yyyy-MM-dd">
					<xsl:value-of select="$fromDate"/>
				</date:reformat>					
			</xsl:when>
			<xsl:when test="str:contains($fromDate, '/') and string-length($fromDate) = 10">
				<date:reformat curFormat="dd/MM/yyyy" newFormat="yyyy-MM-dd">
					<xsl:value-of select="$fromDate"/>
				</date:reformat>					
			</xsl:when>
			<xsl:when test="string-length($fromDate) = 8">
				<date:reformat curFormat="yyyyMMdd" newFormat="yyyy-MM-dd">
					<xsl:value-of select="$fromDate"/>
				</date:reformat>					
			</xsl:when>
			<xsl:when test="string-length($fromDate) = 0">
				<!-- Do nuffin -->
			</xsl:when>
			<xsl:otherwise>
				<mapper:logError>
					Unrecognised date format: <xsl:value-of select="$fromDate"/>
				</mapper:logError>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="TXT">

		<FreeText><xsl:value-of select="Field[3]"/></FreeText>
		<FreeText><xsl:value-of select="Field[4]"/></FreeText>
		<FreeText><xsl:value-of select="Field[5]"/></FreeText>

	</xsl:template>

</xsl:stylesheet>
