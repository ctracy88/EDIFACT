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
            </xsl:variable>-->
            
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
                    <xsl:value-of select="/Batch/ASN[1]/BatchReferences/BatchRef" />
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
                        <xsl:value-of select="Batch/ASN[1]/BatchReferences/test" />
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
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/BatchRef" />
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
        <xsl:variable name="MsgRefNum">
            <xsl:value-of select="UNH/MsgRefNum" />
        </xsl:variable>
        <mapper:incVar name="messageCount" />
        <mapper:setVar name="segmentCount">0</mapper:setVar>
        <UNH>
            <mapper:incVar name="segmentCount" />
            <!-- Unique sequential number which may be checked -->
            <Field>
                <xsl:value-of select="$MsgRefNum" />
            </Field>
            <Field>
                <Field>
					<xsl:value-of select="UNH/MsgType" />
				</Field>
                <Field>
					<xsl:value-of select="UNH/MsgVersion" />
				</Field>
                <Field>
					<xsl:value-of select="UNH/MsgReleaseNum" />
				</Field>
                <Field>
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
                <Field>
					
				</Field>
				<Field/>
				<Field/>
                
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
                    <Field/>
                    <Field/>
					<Field>
						<xsl:value-of select="BGM/DocName" />
					</Field>
                </Field>
                <Field>
                    <xsl:value-of select="BGM/DocNum" />
                </Field>
                <Field>
					<xsl:value-of select="BGM/MsgFunction" />
				</Field>
				<Field>
					<xsl:value-of select="BGM/ResponseType" />
				</Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>10</Field>
                    <!-- qualifier, 137 = document date/time -->
                    <Field>
                        <xsl:value-of select="DTM/ShipmentDate" />
                    </Field>
                    <Field>102</Field>
                    <!-- date format, 203 = CCYYMMDDHHMM -->
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>97</Field>
                    <Field>
						<xsl:value-of select="DTM/TransCreateDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<!--
            <xsl:if test="string-length(Carrier/ShippingBillofLading) &gt; 0">
                <RFF>
                    <mapper:incVar name="segmentCount" />
                    <Field>
                        <Field>BM</Field>
                        
                        <Field>
                            <xsl:value-of select="Carrier/ShippingBillofLading" />
                        </Field>
                    </Field>
                </RFF>
            </xsl:if> -->
			<MEA>
				<mapper:incVar name="segmentCount" />
				<Field>EGW</Field>
				<Field/>
				<Field>
					<Field>
					</Field>
					<Field>
						<xsl:value-of select="MEA/EstGrossWeight" />
					</Field>
				</Field>
			</MEA>
			<MEA>
				<mapper:incVar name="segmentCount" />
				<Field>WT</Field>
				<Field/>
				<Field>
					<Field>
						
					</Field>
					<Field>
						<xsl:value-of select="MEA/TareWeight" />
					</Field>
				</Field>
			</MEA>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>PK</Field>
					<Field>
						<xsl:value-of select="RFF/PackingListNum" />
					</Field>
				</Field>
			</RFF>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>BM</Field>
					
					<Field>
						<xsl:value-of select="RFF/BOLNum" />
					</Field>
				</Field>
			</RFF>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
                <!-- ST = shipto -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.ST/Code" />
                    </Field>
                    <Field />
                    <Field></Field>
                </Field>
            </NAD>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <!-- SE = seller -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/Code" />
                    </Field>
                    <Field />
                    <Field></Field>
                </Field>
            </NAD>
            <!-- Transport details -->
            <TDT>
                <mapper:incVar name="segmentCount" />
                <Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
                <Field>
					<xsl:value-of select="TDT/ConveyRefNum" />
				</Field>
                <Field>
					<Field><xsl:value-of select="TDT/ModeOfTransport" /></Field>
					<Field></Field>
				</Field>
                <Field>
					<Field></Field>
					<Field></Field>
				</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="TDT/SCAC" />
                    </Field>
                    <Field />
                    <Field />
                    <Field />
                </Field>
            </TDT>
            <CPS>
                <mapper:incVar name="segmentCount" />
                <Field>1</Field>
				<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="Details/LineNum" />
						</Field>
						<Field/>
						<Field>
							<Field><xsl:value-of select="Details/BuyerPartNum" /></Field>
							<Field><xsl:value-of select="Details/BuyerPartNumQual" /></Field>
							<Field></Field>
							<Field></Field>
						</Field>
						<Field>
							<Field></Field>
							<Field></Field>
						</Field>
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="Details/AdditionalItemQual" />
							</Field>
							<Field>
								<Field><xsl:value-of select="Details/PONum" /></Field>
								<Field><xsl:value-of select="Details/PONumQual" /></Field>
								<Field></Field>
								<Field></Field>
							</Field>
							<Field>
								<Field><xsl:value-of select="Details/VendorPartNum" /></Field>
								<Field><xsl:value-of select="Details/VendorPartNumQual" /></Field>
								<Field></Field>
								<Field></Field>
							</Field>
						</PIA>
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="Details/DescriptionQual1" />
							</Field>
							<Field>
								<xsl:value-of select="Details/DescriptionQual2" />
							</Field>
							<Field>
								<Field></Field>
								<Field></Field>
								<Field></Field>
								<Field><xsl:value-of select="Details/Description" /></Field>
								<Field></Field>
								<Field></Field>
							</Field>
						</IMD>
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field><xsl:value-of select="Details/DiscreteQtyQual" /></Field>
								<Field><xsl:value-of select="Details/DiscreteQty" /></Field>
								<Field><xsl:value-of select="Details/DiscreteQtyUOM" /></Field>
							</Field>
						</QTY>
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field><xsl:value-of select="Details/CumulativeQtyQual" /></Field>
								<Field><xsl:value-of select="Details/CumulativeQty" /></Field>
								<Field><xsl:value-of select="Details/CumulativeQtyUOM" /></Field>
							</Field>
						</QTY>						
					</LIN>
                </xsl:for-each>
			</CPS>	
				
				
            <CNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>2</Field>
                    <!-- 2 = total number of lines -->
                    <Field>
                        <xsl:value-of select="count(Item)" />
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
                    <xsl:value-of select="$MsgRefNum" />
                </Field>
                <!-- UNH reference number -->
            </UNT>
        </UNH>
    </xsl:template>
    <!--
			Template used to determine if a product is stored in a box or a green tray for Tesco -->
		
		<xsl:template name="determine-product-case-type"><xsl:param name="name" /></xsl:template></xsl:stylesheet>