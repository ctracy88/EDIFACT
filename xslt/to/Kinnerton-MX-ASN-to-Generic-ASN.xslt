<?xml version="1.0"?>
<!--
	MX CSV ASN conversion

	Input: MX CSV
	Output: Generic XML ASN

	Author: Roy Hocknull
	Version: 1.0
	Creation Date: 16-Oct-2013
-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
	xmlns:math="com.css.base.xml.xslt.ext.XsltMathExtension"
	xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension"
	xmlns:flat="com.css.base.xml.xslt.ext.flat.XsltParsedFFVExtension"
	xmlns:csv="com.css.base.xml.xslt.ext.flat.XsltCsvLoaderExtension"
	xmlns:mapper="com.api.tx.MapperEngine"
	xmlns:barcode="com.css.base.utils.Barcode"
	extension-element-prefixes="date math flat csv mapper str">

	<xsl:output method="xml"/>

	<xsl:param name="Profile"/>
	<xsl:param name="HubInfo"/>
	<xsl:param name="ForceTesting"/>

	<xsl:template match="/Document">
		<xsl:variable name="profile" select="document($Profile)/Profile"/>
		<xsl:variable name="hubs" select="document($HubInfo)/Hubs"/>

                <xsl:variable name="EAN" select="HDR/Field[4]"/>

                <xsl:variable name="hubID">
			<xsl:choose>
				<xsl:when test="HDR/Field[4] = 'TESC0001'">TescoUK</xsl:when>
				<xsl:when test="HDR/Field[4] = 'WALG0001'">Walgreens</xsl:when>
				<xsl:otherwise>
		                        <xsl:value-of select="$hubs/Hub[Envelope/Document/@ean = $EAN][Envelope/Document/@id = 'DESADV']/@id"/>
				</xsl:otherwise>
			</xsl:choose>
                </xsl:variable>

		<mapper:logDetail>
			Processing batch for HUB <xsl:value-of select="$hubID"/>
		</mapper:logDetail>

		<mapper:logDetail>
			Contains = <xsl:value-of select="count(HDR)"/> ASNs.
		</mapper:logDetail>

		<xsl:variable name="partner" select="$profile/Partners/Partner[@hubID = $hubID][SupplierIDForCustomer = $EAN]"/>
		<xsl:if test="not($partner)">
			<mapper:logError>
				Cannot locate partner with internal ID: <xsl:value-of select="$hubID"/> and supplier code <xsl:value-of select="$EAN"/>
			</mapper:logError>
		</xsl:if>

		<xsl:variable name="testMode">
			<xsl:choose>
				<xsl:when test="$partner/@testing = 'true' or $ForceTesting = 'true'">true</xsl:when>
				<xsl:otherwise>false</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="hub" select="$hubs/Hub[@id = $hubID]/Envelope[Document/@id = 'DESADV'][@test = $testMode]"/>
		<xsl:if test="not($hub)">
			<mapper:logError>
				Cannot locate hub with internal ID: <xsl:value-of select="$hubID"/> and type DESADV.
			</mapper:logError>
		</xsl:if>

		<xsl:variable name="hubDocument" select="$hub/Document[@id = 'DESADV']"/>
		<xsl:if test="not($hubDocument)">
			<mapper:logError>
				Cannot locate hub DESADV document for: <xsl:value-of select="$hubID"/>
			</mapper:logError>
		</xsl:if>

		<Batch>
			<xsl:apply-templates select="HDR">
				<xsl:with-param name="profile" select="$profile"/>
				<xsl:with-param name="partner" select="$partner"/>
				<xsl:with-param name="hub" select="$hub"/>
				<xsl:with-param name="hubDocument" select="$hubDocument"/>
				<xsl:with-param name="hubID" select="$hubID"/>
			</xsl:apply-templates>
		</Batch>

	</xsl:template>

	<xsl:template match="HDR">
		<xsl:param name="profile"/>
		<xsl:param name="partner"/>
		<xsl:param name="hub"/>
		<xsl:param name="hubDocument"/>
		<xsl:param name="hubID"/>

		<mapper:logDetail>
			ASN# = <xsl:value-of select="Field[14]"/>, Date = <xsl:value-of select="Field[15]"/>
		</mapper:logDetail>

		<ASN type="New">

			<xsl:variable name="SenderANA" select="$partner/SenderEnvEan"/>
			<xsl:variable name="SenderName" select="$partner/SenderEnvName"/>
			<xsl:variable name="ReceiverANA" select="$hub/@ean"/>
			<xsl:variable name="ReceiverName" select="$hub/@name"/>

			<xsl:variable name="testMode">
				<xsl:choose>
					<xsl:when test="$partner/@testing = 'true' or $ForceTesting = 'true'">true</xsl:when>
					<xsl:otherwise>false</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<BatchReferences>
				<xsl:attribute name="test"><xsl:value-of select="$testMode"/></xsl:attribute>
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
				</Address>
				<VatNumber><xsl:value-of select="$profile/Address/@vat"/></VatNumber>
			</Supplier>

			<xsl:choose>
				<xsl:when test="false()"> <!-- string-length(Field[21]) != 0">	 HDR 21 = Order number -->
					<Consignor>
						<EanCode><xsl:value-of select="''"/></EanCode>
						<SuppliersCode><xsl:value-of select="Field[21]"/></SuppliersCode>
						<CustomersCode><xsl:value-of select="''"/></CustomersCode>
						<Name><xsl:value-of select="Field[22]"/></Name>
					</Consignor>
				</xsl:when>
				<xsl:otherwise>
					<Consignor>
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
						</Address>
						<VatNumber><xsl:value-of select="$profile/Address/@vat"/></VatNumber>
					</Consignor>
				</xsl:otherwise>
			</xsl:choose>

			<Customer>
				<EanCode><xsl:value-of select="$hubDocument/@ean"/></EanCode>
				<SuppliersCode><xsl:value-of select="$partner/SupplierIDForCustomer"/></SuppliersCode>
				<CustomersCode/>
				<Name><xsl:value-of select="$hub/../Address/@name"/></Name>
				<Address>
					<Title><xsl:value-of select="$hub/../Address/@a1"/></Title>
					<Street><xsl:value-of select="$hub/../Address/@a2"/></Street>
					<Town><xsl:value-of select="$hub/../Address/@a3"/></Town>
					<City><xsl:value-of select="$hub/../Address/@a4"/></City>
					<PostCode><xsl:value-of select="$hub/../Address/@pc"/></PostCode>
				</Address>
				<VatNumber><xsl:value-of select="$hub/../Address/@vat"/></VatNumber>
			</Customer>

			<Consignee>
				<EanCode>
					<xsl:value-of select="Field[6]"/>
				</EanCode>
				<SuppliersCode>
					<xsl:value-of select="Field[5]"/>
				</SuppliersCode>
				<CustomersCode>
					<xsl:value-of select="Field[7]"/>
				</CustomersCode>
				<Name>
					<xsl:value-of select="Field[8]"/>
				</Name>
				<Address>
					<Title>
						<xsl:value-of select="Field[9]"/>
					</Title>
					<Street>
						<xsl:value-of select="Field[10]"/>
					</Street>
					<Town>
						<xsl:value-of select="Field[11]"/>
					</Town>
					<City>
						<xsl:value-of select="Field[12]"/>
					</City>
					<PostCode>
						<xsl:value-of select="Field[13]"/>
					</PostCode>
					<Country>
						<xsl:value-of select="''"/>
					</Country>
				</Address>
			</Consignee>

			<DeliverTo>
				<EanCode>
					<xsl:value-of select="Field[6]"/>
				</EanCode>
				<SuppliersCode>
					<xsl:value-of select="Field[5]"/>
				</SuppliersCode>
				<CustomersCode>
					<xsl:value-of select="Field[7]"/>
				</CustomersCode>
				<Name>
					<xsl:value-of select="Field[8]"/>
				</Name>
				<Address>
					<Title><xsl:value-of select="Field[9]"/></Title>
					<Street><xsl:value-of select="Field[10]"/></Street>
					<Town><xsl:value-of select="Field[11]"/></Town>
					<City><xsl:value-of select="Field[12]"/></City>
					<PostCode><xsl:value-of select="Field[13]"/></PostCode>
					<Country><xsl:value-of select="''"/></Country>
				</Address>
			</DeliverTo>

			<DocumentNumber>
				<xsl:value-of select="Field[14]"/>
			</DocumentNumber>
			<DocumentDate>
				<date:reformat curFormat="dd/MM/yy" newFormat="yyyy-MM-dd">
					<xsl:value-of select="Field[15]"/>
				</date:reformat>
			</DocumentDate>
			<ShipmentReference>
				<xsl:value-of select="''"/>
			</ShipmentReference>

			<ShippingDate>
				<xsl:if test="string-length(Field[17]) > 0">
					<date:reformat curFormat="dd/MM/yy" newFormat="yyyy-MM-dd">
						<xsl:value-of select="Field[17]"/>
					</date:reformat>
				</xsl:if>
			</ShippingDate>

			<ExpectedDeliveryDate>
				<xsl:choose>
					<xsl:when test="string-length(Field[18]) > 0">
						<date:reformat curFormat="dd/MM/yy" newFormat="yyyy-MM-dd">
							<xsl:value-of select="Field[18]"/>
						</date:reformat>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="date:insert('yyyy-MM-dd')"/>
					</xsl:otherwise>
				</xsl:choose>
			</ExpectedDeliveryDate>

			<Carrier>
				<Name><xsl:value-of select="Field[27]"/></Name>
			</Carrier>

			<DeliveryNoteNumber>
				<xsl:value-of select="Field[14]"/>
			</DeliveryNoteNumber>

			<Measurements>
				<!--<xsl:if test="string-length(Field[26]) &gt; 0">
					<GrossWeight uom="KGM"><xsl:value-of select="Field[26]"/></GrossWeight>
				</xsl:if>
				<xsl:if test="string-length(Field[26]) &gt; 0">
					<NetWeight uom="KGM"><xsl:value-of select="Field[26]"/></NetWeight>
				</xsl:if>
				<xsl:if test="string-length(Field[29]) &gt; 0">
					<Height uom="M"><xsl:value-of select="Field[29] div 100"/></Height>
				</xsl:if>
				<xsl:if test="string-length(Field[27]) &gt; 0">
					<Width uom="M"><xsl:value-of select="Field[27] div 100"/></Width>
				</xsl:if>
				<xsl:if test="Field[27] &gt; 0 and Field[28] &gt; 0 and Field[29] &gt; 0">
					<Volume uom="M3"><xsl:value-of select="(Field[27] * Field[28] * Field[29]) div 100"/></Volume>
				</xsl:if>-->
			</Measurements>

			<xsl:for-each select="PAL">
				<Package type="outer">
					<Markings>
						<CustomersCode></CustomersCode>
						<SuppliersCode></SuppliersCode>
						<Barcode>
							<xsl:value-of select="Field[3]"/>
						</Barcode>
					</Markings>

					<Type>
						<Customers>CHEP</Customers> <!-- CHEP vs EURO? -->
						<Suppliers/>
					</Type>

					<Measurements>
						<!--<xsl:if test="string-length(Field[5]) &gt; 0">
							<GrossWeight uom="KGM"><xsl:value-of select="Field[5]"/></GrossWeight>
						</xsl:if>
						<xsl:if test="string-length(Field[5]) &gt; 0">
							<NetWeight uom="KGM"><xsl:value-of select="Field[5]"/></NetWeight>
						</xsl:if>
						<xsl:if test="string-length(Field[8]) &gt; 0">
							<Height uom="M"><xsl:value-of select="Field[8] div 100"/></Height>
						</xsl:if>
						<xsl:if test="string-length(Field[6]) &gt; 0">
							<Width uom="M"><xsl:value-of select="Field[6] div 100"/></Width>
						</xsl:if>-->
					</Measurements>

					<xsl:for-each select="LNE">
						<Product>
							<LineNumber>
								<xsl:value-of select="Field[22]"/>
							</LineNumber>
							<EanCode>
								<xsl:value-of select="Field[4]"/>
							</EanCode>
							<SuppliersCode>
								<xsl:value-of select="Field[3]"/>
							</SuppliersCode>
							<CustomersCode>
								<xsl:value-of select="Field[6]"/>
							</CustomersCode>
							<PalletCode>
								<xsl:value-of select="Field[5]"/>
							</PalletCode>
							<Name>
								<xsl:value-of select="concat(Field[8], Field[9])"/>
							</Name>

							<Quantity>
								<Amount>
									<xsl:value-of select="Field[14]"/>
								</Amount>
								<AmountPerUnit>
									<xsl:value-of select="Field[10]"/>
								</AmountPerUnit>
								<MeasureIndicator>
									<xsl:value-of select="Field[13]"/>
								</MeasureIndicator>
							</Quantity>

							<OrderNumber>
								<Customers>
									<xsl:value-of select="Field[19]"/>	<!-- order number is position 19 at line level (21 at header) -->
								</Customers>
							</OrderNumber>

							<OrderDate>
								<Customers>
									<xsl:if test="string-length(Field[20]) > 0">
										<date:reformat curFormat="dd/MM/yy" newFormat="yyyy-MM-dd">
											<xsl:value-of select="Field[20]"/>
										</date:reformat>
									</xsl:if>
								</Customers>
							</OrderDate>

							<ExpiryDate>
								<xsl:if test="string-length(Field[21]) > 0">
									<date:reformat curFormat="dd/MM/yy" newFormat="yyyy-MM-dd">
										<xsl:value-of select="Field[21]"/>
									</date:reformat>
								</xsl:if>
							</ExpiryDate>

							<DeliveryNoteNumber>
								<xsl:value-of select="''"/>
							</DeliveryNoteNumber>

						</Product>
					</xsl:for-each>

				</Package>
			</xsl:for-each>

		</ASN>
	</xsl:template>

</xsl:stylesheet>
