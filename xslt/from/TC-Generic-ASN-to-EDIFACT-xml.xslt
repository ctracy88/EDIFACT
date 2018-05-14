<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML ASN into a specific Tesco EANCOM D96A ASN.
	
	Input: Generic XML Invoice.
	Output: Tesco EANCOM D96A Invoice.
	
	Author: Pete Shelmerdine
	Version: 1.0
	Creation Date: 24-Oct-2006
	
	Last Modified Date: 24-Oct-2006
	Last Modified By: Pete Shelmerdine	
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension" xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension" xmlns:edifact="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension" xmlns:mapper="com.api.tx.MapperEngine" extension-element-prefixes="date mapper str edifact">
    <xsl:output method="xml" />
    <xsl:param name="SenderEnvelopeQualifier" />
    <xsl:param name="TestMode" />
    <!-- true if to override the partner default -->
    <xsl:param name="CustomerCodeForSupplier" />
    <!-- Optional if not supplied in the generic XML -->
    <xsl:param name="Network" />
    <!-- AS2 or TGMS. If not specified then it defaults to TGMS -->
    <xsl:param name="Container" />
    <!-- If not in the Type/Customers or Type/Suppliers then you can use this. Set to CHEP or EURO -->
    <xsl:param name="BoxType" />
    <!-- If not in the SuppliedIn then you can use this. Set to TRAY or BOX -->
    <xsl:param name="NetworkPassword" />
    <xsl:param name="UseConsolidator" select="'true'" />
    <!-- Additional text to include within the batch reference stored in the property files.
			Useful if more than one account exists on the same supplier ANA. -->
    <xsl:param name="BatchRefText" />
    <xsl:template match="/">
        <xsl:apply-templates select="Batch" />
    </xsl:template>
    <xsl:template match="Batch">
        <mapper:logMessage>
				Transforming to Tesco Eancom EDI ASNs
			</mapper:logMessage>
        <!-- This is the ANA to which this document is intended -->
        <xsl:variable name="receiverANA" select="/Batch/ASN[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/ASN[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/ASN[1]/Supplier/CustomersCode" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Document type="EDIFACT" wrapped="false">
            <xsl:attribute name="syntax">
                <xsl:value-of select="'UNOA'" />
            </xsl:attribute>
            <xsl:attribute name="version">
                <xsl:value-of select="'3'" />
            </xsl:attribute>
            <!-- Incremental ref for batch -->
            <xsl:variable name="BatchGenNumber">
                <mapper:genNum>
                    <xsl:choose>
                        <xsl:when test="string-length($BatchRefText) &gt; 0">
                            <xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', $BatchRefText, '.', 'TESCO', '.', 'DESADV')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', 'TESCO', '.', 'DESADV')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </mapper:genNum>
            </xsl:variable>
            <!-- 
					Tesco want <SupplierID><version no - nnnn><gen num>0 in the UNB reference number. This roughly equates to 
					the FIL shaz in Tradacoms.
				-->
            <xsl:variable name="BatchRef">
                <xsl:if test="string-length(/Batch/ASN[1]/Supplier/CustomersCode) = 0 and string-length($CustomerCodeForSupplier) = 0">
                    <mapper:logError>
							It is required that the customer's code for supplier be supplied.
						</mapper:logError>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                        <xsl:value-of select="concat($CustomerCodeForSupplier, '0001', str:pad($BatchGenNumber, 4, '0', 'true'), '0')" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(/Batch/ASN[1]/Supplier/CustomersCode, '0001', str:pad($BatchGenNumber, 4, '0', 'true'), '0')" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <mapper:logDetail>
					File Generation number: <xsl:value-of select="$BatchRef" /></mapper:logDetail>
            <mapper:setVar name="messageCount">0</mapper:setVar>
            <UNB>
                <Field>
                    <Field>UNOA</Field>
                    <Field>3</Field>
                </Field>
                <!-- Sender ANA and Qualifier -->
                <Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <!-- Receiver ANA and Qualifier -->
                <Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/ReceiverCodeQualifier" />
                    </Field>
                </Field>
                <!-- Date and Time stamps -->
                <Field>
                    <Field>
                        <xsl:value-of select="date:insert('yyMMdd')" />
                    </Field>
                    <Field>
                        <xsl:value-of select="date:insert('hhmm')" />
                    </Field>
                </Field>
                <!-- Interchange Reference Number -->
                <Field>
                    <xsl:value-of select="$BatchRef" />
                </Field>
                <!-- Network Password -->
                <Field>
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <!-- Application Reference -->
                <Field>DESADV</Field>
                <Field />
                <!-- Processing Priority -->
                <Field />
                <!-- Acknowledgement Request -->
                <Field />
                <!-- Communications Agreement -->
                <Field>
                    <!-- Test Indicator -->
                    <xsl:if test="/Batch/ASN[1]/BatchReferences/@test = 'true'">
                        <xsl:value-of select="'1'" />
                    </xsl:if>
                </Field>
                <!-- Process each ASN -->
                <xsl:apply-templates select="ASN">
                    <xsl:with-param name="batchRef" select="$BatchGenNumber" />
                </xsl:apply-templates>
                <UNZ>
                    <!-- Number of Documents -->
                    <Field>
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <!-- Interchange Reference Number -->
                    <Field>
                        <xsl:value-of select="$BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="ASN">
        <xsl:param name="batchRef" />
        <!-- Create a generation number which I'll use in the UNH -->
        <xsl:variable name="GenNumber">
            <xsl:value-of select="position()" />
        </xsl:variable>
        <xsl:variable name="AsnUnhRef">
            <xsl:value-of select="round(format-number($GenNumber, '0.00'))" />
        </xsl:variable>
        <mapper:incVar name="messageCount" />
        <mapper:setVar name="segmentCount">0</mapper:setVar>
        <UNH>
            <mapper:incVar name="segmentCount" />
            <!-- Unique sequential number which may be checked -->
            <Field>
                <xsl:value-of select="$AsnUnhRef" />
            </Field>
            <Field>
                <Field>DESADV</Field>
                <Field>D</Field>
                <Field>96A</Field>
                <Field>UN</Field>
                <Field>DESAD3</Field>
                <!-- This is a back-office system Tesco hack -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>351</Field>
                    <!-- Doc type 351 = despatch advice -->
                    <Field />
                    <Field>9</Field>
                    <!-- Message function 9 = original invoice -->
                </Field>
                <Field>
                    <xsl:value-of select="str:pad(DocumentNumber, 9, '0', 'true')" />
                </Field>
                <Field>9</Field>
                <!-- Message function 9 = original invoice -->
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <!-- qualifier, 137 = document date/time -->
                    <Field>
                        <xsl:value-of select="date:insert('yyyyMMddHHmm')" />
                    </Field>
                    <Field>203</Field>
                    <!-- date format, 203 = CCYYMMDDHHMM -->
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <xsl:if test="string-length(ExpectedDeliveryDate) = 0">
                    <mapper:logError>
							Booking in date (expected delivery date) is required by Tesco.
						</mapper:logError>
                </xsl:if>
                <Field>
                    <Field>191</Field>
                    <!-- qualifier, 191 = booking date/time -->
                    <Field>
                        <date:reformat curFormat="yyyy-MM-ddHH:mm" newFormat="yyyyMMddHHmm">
                            <xsl:value-of select="concat(ExpectedDeliveryDate, '00:00')" />
                            <!-- 00:00 is OK if not supplied -->
                        </date:reformat>
                    </Field>
                    <Field>203</Field>
                    <!-- date format, 203 = CCYYMMDDHHMM -->
                </Field>
            </DTM>
            <!-- This is mandatory only if fresh produce is being supplied.
						Tesco Quote:
						 This segment is used to provide references that apply to the whole transaction. 
						 Although this segment was originally created for a potential future requirement to 
						 allow the RFID for the load to be defined, it will be used to hold the load 
						 reference number for Fresh loads. 				
				-->
            <xsl:if test="string-length(DeliverFrom/LoadingReferenceNumber) &gt; 0">
                <RFF>
                    <mapper:incVar name="segmentCount" />
                    <Field>
                        <Field>PK</Field>
                        <!-- PK = packing list number -->
                        <Field>
                            <xsl:value-of select="DeliverFrom/LoadingReferenceNumber" />
                        </Field>
                    </Field>
                </RFF>
            </xsl:if>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <!-- BY = buyer -->
                <Field>
                    <Field>
                        <xsl:value-of select="Customer/EanCode" />
                    </Field>
                    <Field />
                    <Field>9</Field>
                    <!-- qualifier, 9 = EAN -->
                </Field>
            </NAD>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SE</Field>
                <!-- SE = seller -->
                <Field>
                    <Field>
                        <xsl:value-of select="Supplier/EanCode" />
                    </Field>
                    <Field />
                    <Field>9</Field>
                    <!-- qualifier, 9 = EAN -->
                </Field>
            </NAD>
            <!--
					This is only really needed when the consolidator is used to supply multiple
					supplier's shipments in one shipment.
				-->
            <xsl:if test="Consignor/@outputNadCS != 'false'">
                <NAD>
                    <mapper:incVar name="segmentCount" />
                    <Field>CS</Field>
                    <!-- CS = consolidator -->
                    <Field>
                        <Field>
                            <xsl:value-of select="Consignor/EanCode" />
                        </Field>
                        <Field />
                        <Field>9</Field>
                    </Field>
                </NAD>
            </xsl:if>
            <!-- Transport details -->
            <TDT>
                <mapper:incVar name="segmentCount" />
                <Field>20</Field>
                <!-- 20 = main carriage transport -->
                <Field />
                <Field>30</Field>
                <!-- 30 = road transport -->
                <Field />
                <Field>
                    <Field>
                        <xsl:value-of select="Consignor/EanCode" />
                    </Field>
                    <Field />
                    <Field />
                    <Field>
                        <xsl:value-of select="Consignor/Name" />
                    </Field>
                </Field>
                <LOC>
                    <mapper:incVar name="segmentCount" />
                    <Field>7</Field>
                    <!-- 7 = place of delivery -->
                    <Field>
                        <xsl:value-of select="Consignee/EanCode" />
                    </Field>
                </LOC>
            </TDT>
            <CPS>
                <mapper:incVar name="segmentCount" />
                <Field>1</Field>
                <!-- 1 = top level, aka entire shipment -->
                <PAC>
                    <mapper:incVar name="segmentCount" />
                    <Field>
                        <xsl:value-of select="count(Package)" />
                    </Field>
                    <!-- Number of packages in the consignment -->
                </PAC>
                <xsl:for-each select="Package">
                    <CPS>
                        <mapper:incVar name="segmentCount" />
                        <!-- instance counter - starts from 2 -->
                        <!--							<Field><xsl:value-of select="position() + 1"/></Field> -->
                        <!-- Parent = CPS 1 which is the shipment -->
                        <!--							<Field>1</Field> -->
                        <Field>
                            <xsl:value-of select="'2'" />
                        </Field>
                        <!-- Tesco change from original spec (above) -->
                        <Field>
                            <xsl:value-of select="position()" />
                        </Field>
                        <PAC>
                            <mapper:incVar name="segmentCount" />
                            <Field>1</Field>
                            <!-- Number of packages in the consignment, always 1 -->
                            <Field>
                                <Field></Field>
                                <!-- package code -->
                                <!-- <Field>52</Field> -->
                                <!-- 52 = Package barcoded UCC or EAN-128, only if supplied, or else leave blank -->
                            </Field>
                            <Field>
                                <!-- 201 = Euro Pallet, 202 = CHEP pallet -->
                                <xsl:choose>
                                    <xsl:when test="Type/Customers = 'CHEP'">202</xsl:when>
                                    <xsl:when test="Type/Suppliers = 'CHEP'">202</xsl:when>
                                    <xsl:when test="Type/Customers = 'EURO'">201</xsl:when>
                                    <xsl:when test="Type/Suppliers = 'EURO'">201</xsl:when>
                                    <xsl:when test="$Container = 'EURO'">201</xsl:when>
                                    <xsl:when test="$Container = 'CHEP'">202</xsl:when>
                                    <xsl:otherwise>
                                        <mapper:logError>
												Unknown shipping container type: <xsl:value-of select="Type" />. Expecting CHEP or EURO.
											</mapper:logError>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </Field>
                            <!-- Package ID - SSCC code -->
                            <PCI>
                                <mapper:incVar name="segmentCount" />
                                <Field>33E</Field>
                                <!-- 33E = Serial Shipping Container Code (SSCC) -->
                                <GIN>
                                    <mapper:incVar name="segmentCount" />
                                    <Field>BJ</Field>
                                    <!-- BJ = Serial shipping container code -->
                                    <!-- This is mandatory only for SSCC deliveries. It defaults to 000000000000000000 for non-SSCC suppliers -->
                                    <Field tag="SSCC" minLen="18" maxLen="18">
                                        <xsl:choose>
                                            <xsl:when test="string-length(Markings/Barcode) = 18">
                                                <xsl:value-of select="Markings/Barcode" />
                                            </xsl:when>
                                            <xsl:when test="string-length(Markings/Barcode) = 0">
                                                <xsl:value-of select="'000000000000000000'" />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <mapper:logError>
														SSCC is not 18 digits: <xsl:value-of select="Markings/Barcode" /></mapper:logError>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </Field>
                                </GIN>
                                <xsl:for-each select="Product">
                                    <LIN>
                                        <mapper:incVar name="segmentCount" />
                                        <Field>
                                            <xsl:value-of select="position()" />
                                        </Field>
                                        <!-- line number -->
                                        <Field />
                                        <Field>
                                            <!-- EAN code of item -->
                                            <Field tag="LIN-Barcode" minLen="8" maxLen="14">
                                                <!-- May be Dun-14 or EAN-13, UPC-12 -->
                                                <xsl:choose>
                                                    <xsl:when test="string-length(PackageCode) = 14">
                                                        <xsl:value-of select="PackageCode" />
                                                    </xsl:when>
                                                    <xsl:when test="string-length(EanCode) = 14">
                                                        <xsl:value-of select="EanCode" />
                                                    </xsl:when>
                                                    <xsl:when test="string-length(EanCode) = 13">
                                                        <xsl:value-of select="EanCode" />
                                                    </xsl:when>
                                                    <!-- 14 or 13 digits allowed ONLY for Tesco
														<xsl:when test="string-length(EanCode) = 12"><xsl:value-of select="EanCode"/></xsl:when>
														<xsl:when test="string-length(EanCode) = 8"><xsl:value-of select="EanCode"/></xsl:when>
-->
                                                    <xsl:otherwise>
                                                        <mapper:logError>
																Barcode is not 13 or 14 digits: <xsl:value-of select="PackageCode" />, <xsl:value-of select="EanCode" /></mapper:logError>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </Field>
                                            <Field>EN</Field>
                                            <!-- EN = EAN code -->
                                        </Field>
                                        <xsl:variable name="orderNumber">
                                            <xsl:choose>
                                                <xsl:when test="string-length(OrderNumber/Customers) &gt; 0">
                                                    <xsl:value-of select="OrderNumber/Customers" />
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="../../OrderNumber/Customers" />
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:if test="string-length($orderNumber) = 0">
                                            <mapper:logError>
													The Tesco order number must be supplied. The format is either LMNNNNNNNNNNN or NNNNNNNN.
												</mapper:logError>
                                        </xsl:if>
                                        <xsl:if test="string-length($orderNumber) != 8 and string-length($orderNumber) != 13">
                                            <mapper:logError>
													The Tesco order number is invalid <xsl:value-of select="$orderNumber" />. The format is either LMNNNNNNNNNNN or NNNNNNNN.
												</mapper:logError>
                                        </xsl:if>
                                        <xsl:if test="string-length($orderNumber) = 13 and not(starts-with($orderNumber, 'LM'))">
                                            <mapper:logError>
													The Tesco order number is invalid <xsl:value-of select="$orderNumber" />. The format is either LMNNNNNNNNNNN or NNNNNNNN.
												</mapper:logError>
                                        </xsl:if>
                                        <PIA>
                                            <mapper:incVar name="segmentCount" />
                                            <Field>1</Field>
                                            <!-- 1 = additional information -->
                                            <Field>
                                                <Field>
                                                    <xsl:value-of select="$orderNumber" />
                                                </Field>
                                                <Field>ORD</Field>
                                                <!-- ORD = Order number -->
                                            </Field>
                                        </PIA>
                                        <!-- The del number is optional -->
                                        <xsl:choose>
                                            <xsl:when test="string-length(DeliveryNoteNumber) &gt; 0">
                                                <PIA>
                                                    <mapper:incVar name="segmentCount" />
                                                    <Field>1</Field>
                                                    <!-- 1 = additional information -->
                                                    <Field>
                                                        <Field>
                                                            <xsl:value-of select="DeliveryNoteNumber" />
                                                        </Field>
                                                        <Field>DEL</Field>
                                                        <!-- DEL = delivery note number -->
                                                    </Field>
                                                </PIA>
                                            </xsl:when>
                                            <xsl:when test="string-length(../../DeliveryNoteNumber) &gt; 0">
                                                <PIA>
                                                    <mapper:incVar name="segmentCount" />
                                                    <Field>1</Field>
                                                    <!-- 1 = additional information -->
                                                    <Field>
                                                        <Field>
                                                            <xsl:value-of select="../../DeliveryNoteNumber" />
                                                        </Field>
                                                        <Field>DEL</Field>
                                                        <!-- DEL = delivery note number -->
                                                    </Field>
                                                </PIA>
                                            </xsl:when>
                                        </xsl:choose>
                                        <!-- Quantity of cases shipped on this pallet -->
                                        <QTY>
                                            <mapper:incVar name="segmentCount" />
                                            <Field>
                                                <Field>12</Field>
                                                <!-- 12 = shipped quantity -->
                                                <Field>
                                                    <xsl:value-of select="edifact:convertToEdifactDecimal(Quantity/Amount)" />
                                                </Field>
                                            </Field>
                                        </QTY>
                                        <!-- This is optional, but mandatory for lines that are ordered by the case and supplied
														with a variation of weight, such as fresh meat. -->
                                        <xsl:if test="Quantity/LineWeight &gt; 0">
                                            <QTY>
                                                <mapper:incVar name="segmentCount" />
                                                <Field>
                                                    <Field>12</Field>
                                                    <!-- 12 = shipped quantity -->
                                                    <Field>
                                                        <xsl:value-of select="edifact:convertToEdifactDecimal(Quantity/LineWeight)" />
                                                    </Field>
                                                    <Field>
                                                        <xsl:choose>
                                                            <xsl:when test="Quantity/MeasureIndicator = 'Kilogram'">KGM</xsl:when>
                                                            <xsl:otherwise>
                                                                <mapper:logError>
																		Unrecognised UOM in weighted line: <xsl:value-of select="Quantity/MeasureIndicator" /></mapper:logError>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </Field>
                                                </Field>
                                            </QTY>
                                        </xsl:if>
                                        <!-- The sell-by date is required, though only accurate for food goods. If not food then
												 	 this is set to the current date as dummy data. -->
                                        <DTM>
                                            <mapper:incVar name="segmentCount" />
                                            <Field>
                                                <Field>36</Field>
                                                <!-- 36 = expiry date -->
                                                <Field tag="DTM-Shipped" minLen="1">
                                                    <date:reformat curFormat="yyyy-MM-dd" newFormat="yyyyMMdd">
                                                        <xsl:choose>
                                                            <xsl:when test="string-length(ExpiresDate) &gt; 0">
                                                                <xsl:value-of select="ExpiresDate" />
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="date:insert('yyyy-MM-dd')" />
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </date:reformat>
                                                </Field>
                                                <Field>102</Field>
                                            </Field>
                                        </DTM>
                                        <!-- Whether the product is supplied in a BOX or a green plastic TRAY on the pallet -->
                                        <FTX>
                                            <mapper:incVar name="segmentCount" />
                                            <Field>AAA</Field>
                                            <Field />
                                            <Field />
                                            <Field>
                                                <xsl:choose>
                                                    <xsl:when test="SuppliedIn = 'BOX'">BOX</xsl:when>
                                                    <xsl:when test="SuppliedIn = 'TRAY'">TRAY</xsl:when>
                                                    <xsl:when test="$BoxType = 'BOX'">BOX</xsl:when>
                                                    <xsl:when test="$BoxType = 'TRAY'">TRAY</xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:call-template name="determine-product-case-type">
                                                            <xsl:with-param name="name" select="Name" />
                                                        </xsl:call-template>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </Field>
                                        </FTX>
                                    </LIN>
                                </xsl:for-each>
                            </PCI>
                        </PAC>
                    </CPS>
                </xsl:for-each>
            </CPS>
            <CNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>2</Field>
                    <!-- 2 = total number of lines -->
                    <Field>
                        <xsl:value-of select="count(Package/Product)" />
                    </Field>
                </Field>
            </CNT>
            <UNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <mapper:getVar name="segmentCount" />
                </Field>
                <!-- number of segments in message -->
                <Field>
                    <xsl:value-of select="$AsnUnhRef" />
                </Field>
                <!-- UNH reference number -->
            </UNT>
        </UNH>
    </xsl:template>
    <!--
			Template used to determine if a product is stored in a box or a green tray for Tesco -->
		--&gt;
		<xsl:template name="determine-product-case-type"><xsl:param name="name" /></xsl:template></xsl:stylesheet>