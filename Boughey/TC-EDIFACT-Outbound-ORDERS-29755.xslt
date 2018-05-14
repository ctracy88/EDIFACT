<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML ORDERS into a EDIFACT D96A ORDERS.
	
	Input: Generic XML ORDERS.
	Output: EANCOM D96A ORDERS.
	
	Author: Charlie Tracy
	Version: 1.0
	Creation Date: 08-Dec-2015
		
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
		
		<xsl:variable name="receiverANA" select="/Batch/Order[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/Order[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/Order[1]/Supplier/CustomersCode" />
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
 				<mapper:setVar name="messageCount">0</mapper:setVar>
			<UNB>
                <Field> <!-- UNB 1-->
                    <Field>UNOA</Field> <!-- UNB 1.1-->
                    <Field>3</Field> <!-- UNB 1.2-->
                </Field>
                <Field> <!-- UNB 2-->
                    <Field> <!-- UNB 2.1-->
                        <xsl:value-of select="/Batch/Order[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field> <!-- UNB 2.2-->
                        <xsl:value-of select="/Batch/Order[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/Order[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field> <!-- UNB 3.2-->
                        <xsl:value-of select="/Batch/Order[1]/BatchReferences/ReceiverCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 4-->
                    <Field> <!-- UNB 4.1 -->
                        <xsl:value-of select="date:insert('yyMMdd')" />
                    </Field>
                    <Field> <!-- UNB 4.2 -->
                        <xsl:value-of select="date:insert('hhmm')" />
                    </Field>
                </Field> 
                <Field> <!-- UNB 5 -->
                    <xsl:value-of select="/Batch/Order[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field>ORDERS</Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field /> <!-- UNB 9 -->
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="/Batch/Order[1]/BatchReferences/test" />
                </Field>
                <xsl:apply-templates select="Order">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/Order[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="Order">
        <xsl:param name="batchRef" />
        <xsl:variable name="GenNumber">
            <xsl:value-of select="position()" />
        </xsl:variable>
        <xsl:variable name="MsgRefNum">
            <xsl:value-of select="UNH/MsgRefNum" />
        </xsl:variable>
        <mapper:incVar name="messageCount" />
        <mapper:setVar name="segmentCount">0</mapper:setVar>
        <UNH>
            <mapper:incVar name="segmentCount" />
             <Field> <!-- UNH 1 -->
                <xsl:value-of select="$MsgRefNum" />
            </Field>
            <Field> <!-- UNH 2 -->
                <Field> <!-- UNH 2.1 -->
					<xsl:value-of select="UNH/MsgType" />
				</Field>
                <Field> <!-- UNH 2.2 -->
					<xsl:value-of select="UNH/MsgVersion" />
				</Field>
                <Field> <!-- UNH 2.3 -->
					<xsl:value-of select="UNH/MsgReleaseNum" />
				</Field>
                <Field> <!-- UNH 2.4 -->
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
				<Field/> <!-- UNH 2.5 -->
				<Field/> <!-- UNH 2.6 -->
				<Field/> <!-- UNH 2.7 -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field> <!-- BGM 1 -->
                    <Field> <!-- BGM 1.1 -->
						<xsl:value-of select="BGM/Type" />
					</Field>
                    <Field/><!-- BGM 1.2 -->
                    <Field/><!-- BGM 1.3-->
					<Field/><!-- BGM 1.4 -->
				</Field>
		       <Field> <!-- BGM 2 -->
                    <xsl:value-of select="BGM/DepositorOrderNumber" />
                </Field>
                <Field> <!-- BGM 3 -->
					<xsl:value-of select="BGM/MsgFunction" />
				</Field>
				<Field> <!-- BGM 4 -->
					<xsl:value-of select="BGM/ResponseType" />
				</Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="DTM/PODate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>4</Field>
                    <Field>
                        <xsl:value-of select="DTM/OrderDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<xsl:variable name="DeliveryTime">
				<date:reformat curFormat="HH:mm:ss" newFormat="HHmmss">
					<xsl:value-of select="DTM/DeliveryTime"/>
				</date:reformat>
			</xsl:variable>
			<xsl:if test="string-length(DTM/EarliestDeliveryDate) &gt; 0">
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>64</Field>
                    <Field>
                        <xsl:value-of select="concat(DTM/EarliestDeliveryDate,$DeliveryTime)" />
                    </Field>
                    <Field>204</Field>
                </Field>
            </DTM>
			</xsl:if>
			<xsl:variable name="PickupTime">
				<date:reformat curFormat="HH:mm:ss" newFormat="HHmmss">
					<xsl:value-of select="DTM/PickupTime"/>
				</date:reformat>
			</xsl:variable>
			<xsl:if test="string-length(DTM/LatestDeliveryDate) &gt; 0">
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>63</Field>
                    <Field>
                        <xsl:value-of select="concat(DTM/LatestDeliveryDate,$PickupTime)" />
                    </Field>
                    <Field>204</Field>
                </Field>
            </DTM>
			</xsl:if>
			<xsl:if test="string-length(DTM/PickupDate) &gt; 0">
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>200</Field>
                    <Field>
                        <xsl:value-of select="DTM/PickupDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			</xsl:if>
			<xsl:if test="string-length(FTX/TermsNote) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAB</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="FTX/TermsNote" />
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(FTX/OrderNote) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>COI</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="FTX/OrderNote" />
				</Field>
			</FTX>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
					<xsl:value-of select="RFF/PONumber" />
					</Field>
				</Field>
			</RFF>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>POR</Field>
					<Field>
						<xsl:value-of select="RFF/OrderType" />
					</Field>
				</Field>
			</RFF>
			<xsl:if test="string-length(RFF/ShippingBookingNumber) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>BN</Field>
					<Field>
					<xsl:value-of select="RFF/ShippingBookingNumber" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/VendorNumber) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>IA</Field>
					<Field>
						<xsl:value-of select="RFF/VendorNumber" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ADE</Field>
					<Field>
						<xsl:value-of select="RFF/AccountNumberBilling" />
					</Field>
				</Field>
			</RFF>
 			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <!-- BY = Buyer -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address2" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/ZipCode" />
					</Field>
				</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.BY/City" />
				</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.BY/Country" />
				</Field>
				
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <!-- SU = Supplier -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address2" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/ZipCode" />
					</Field>
				</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.SU/City" />
				</Field>
				<Field></Field>
				<Field></Field>
				<Field>
				<xsl:value-of select="NAD.SU/Country" />	
				</Field>
				
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <!-- DP = Ship To -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.DP/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.DP/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.DP/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.DP/Address2" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.DP/ZipCode" />
					</Field>
				</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.DP/City" />
				</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.DP/Country" />
				</Field>
					<CTA>
						<mapper:incVar name="segmentCount" />
						<Field>CN</Field>
						<Field>
							<Field>
							<xsl:value-of select="NAD.DP/CTA/ShipToLocationID" />
							</Field>
						</Field>
					</CTA>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <!-- SF = Ship From -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/ShipFromAddressCode" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
			</NAD>
			<CUX>
                <mapper:incVar name="segmentCount" />
				<Field>
					<Field>2</Field>
					<Field>	<xsl:value-of select="CUX/Currency" />
					</Field>
					<Field>9</Field>
				</Field>
            </CUX>
			<TOD>
                <mapper:incVar name="segmentCount" />
				<Field></Field>
				<Field></Field>
				<Field>
					<Field></Field>
					<Field></Field>
					<Field></Field>
					<Field>
					<xsl:value-of select="TOD/Routing" />
					</Field>
				</Field>
            </TOD>
			<xsl:if test="string-length(ALC/AllowanceAmount) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="ALC/AllowanceChargeType" />
				</Field>
				<Field>
					<xsl:value-of select="ALC/AllowanceType" />
				</Field>
				<Field>
					<xsl:value-of select="ALC/AllowanceAmount" />
				</Field>
			</ALC>
			</xsl:if>
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/LineNum" />
						</Field>
						<Field></Field>
						<Field>
							<Field><xsl:value-of select="LIN/EANNum" /></Field>
							<Field>EN</Field>
						</Field>
						<xsl:if test="string-length(LIN/PIA/BuyerItemNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/BuyerItemNum" />
								</Field>
								<Field>IN</Field>
							</Field>
						</PIA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PIA/VendorItemNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/VendorItemNum" />
								</Field>
								<Field>VN</Field>
							</Field>
						</PIA>
						</xsl:if>
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field></Field>
							<Field></Field>
							<Field>
								<Field></Field>
								<Field></Field>
								<Field></Field>
								<Field></Field>
								<Field>
									<xsl:value-of select="LIN/IMD/Description" />
								</Field>
							</Field>
						</IMD>
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>21</Field>
								<Field><xsl:value-of select="LIN/QTY/Qty" /></Field>
							</Field>
						</QTY>
						<xsl:if test="string-length(LIN/PRI/CalculationPrice) &gt; 0">
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAA</Field>
								<Field><xsl:value-of select="LIN/PRI/CalculationPrice" /></Field>
							</Field>
						</PRI>
						</xsl:if>
					</LIN>
                </xsl:for-each>	
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>	
            <UNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <mapper:getVar name="segmentCount" />
                </Field>
                <!-- number of segments in message -->
                <Field>
                    <xsl:value-of select="$MsgRefNum" />
                </Field>
                <!-- UNH reference number -->
            </UNT>
        </UNH>
    </xsl:template>
</xsl:stylesheet>