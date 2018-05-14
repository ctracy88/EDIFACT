<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML ASN into a specific Cummins EANCOM D98B ASN.
	
	Input: Generic XML Invoice.
	Output: Cummins EANCOM D98B DESADV.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: August 1, 2016
	
	Last Modified Date: 
	Last Modified By: 	
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
            <mapper:setVar name="messageCount">0</mapper:setVar>
            <UNB>
                <Field>
                    <Field>UNOA</Field>
                    <Field>1</Field>
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
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/Location" />
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
		<mapper:setVar name="packageIncrementer">0</mapper:setVar>
		<xsl:variable name="currentPackage"></xsl:variable>
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
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
					<Field>
						<xsl:value-of select="BGM/DocNum" />
					</Field>
					<Field>
						<xsl:value-of select="BGM/MsgFunction" />
					</Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>11</Field>
                    <Field>
                        <xsl:value-of select="concat(DTM/DespatchDate,DTM/DespatchTime)" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>17</Field>
                    <Field>
						<xsl:value-of select="concat(DTM/EstimatedDeliveryDate,DTM/EstimatedDeliveryTime)" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>AAU</Field>
					<Field>
						<xsl:value-of select="RFF/DespatchNoteNum" />
					</Field>
				</Field>
			</RFF>
			<xsl:if test="string-length(NAD.CB/Code) &gt; 0">
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>CB</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.CB/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.CB/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.CB/Name" />
				</Field>
            </NAD>
			</xsl:if>
			<xsl:if test="string-length(NAD.FW/Code) &gt; 0">
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>FW</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.FW/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.FW/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.FW/Name" />
				</Field>
            </NAD>
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.SF/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.SF/Name" />
				</Field>
            </NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.ST/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.ST/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.ST/Name" />
				</Field>
					<LOC>
						<mapper:incVar name="segmentCount" />
						<Field>7</Field>
						<Field>
							<xsl:value-of select="NAD.ST/LOC/DeliveryLocation" />
						</Field>
					</LOC>
					<RFF>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>PK</Field>
							<Field>
								<xsl:value-of select="NAD.ST/RFF/PackingListNum" />
							</Field>
						</Field>
					</RFF>
            </NAD>
            <TDT>
                <mapper:incVar name="segmentCount" />
                <Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
                <Field>
					<xsl:value-of select="TDT/ConveyanceRefNum" />
				</Field>
                <Field/>
                <Field>
					<xsl:value-of select="TDT/ModeOfTransport" />
				</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="TDT/SCAC" />
                    </Field>
					<Field></Field>
					<Field>182</Field>
					<Field>
						<xsl:value-of select="TDT/Routing" />
					</Field>
                </Field>
            </TDT>
			<xsl:if test="string-length(EQD/EquipmentQual) &gt; 0">
			<EQD>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="EQD/EquipmentQual" />
				</Field>
				<Field>
					<xsl:value-of select="EQD/EquipmentNum" />
				</Field>
			</EQD>
			</xsl:if>
			<xsl:if test="string-length(SEL/SealNum) &gt; 0">
			<SEL>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="SEL/SealNum" />
				</Field>
				<Field>
					<xsl:value-of select="SEL/SealingPartyCode" />
				</Field>
			</SEL>
			</xsl:if>
			<CPS>
				<mapper:incVar name="segmentCount" />
				<Field>1</Field>
				<Field/>
				<Field>4</Field>
			</CPS>
			<PAC>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PAC/NumOfPackages" />
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="PAC/PackageType" />
					</Field>
				</Field>
			</PAC>
			<QTY>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>52</Field>
					<Field>
						<xsl:value-of select="QTY/QtyPerPack" />
					</Field>
					<Field>
						<xsl:value-of select="QTY/QtyPerPackUOM" />
					</Field>
				</Field>
			</QTY>
			<xsl:if test="string-length(PCI/MarkInstr) &gt; 0">
			<PCI>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PCI/MarkInstr" />
				</Field>
			</PCI>
			</xsl:if>
			<xsl:if test="string-length(GIR/PackagingIDNum) &gt; 0">
			<GIR>
				<mapper:incVar name="segmentCount" />
				<Field>3</Field>
				<Field>
					<Field>
						<xsl:value-of select="GIR/PackagingIDNum" />
					</Field>
					<Field>
						<xsl:value-of select="GIR/PackagingIDType" />
					</Field>
				</Field>
			</GIR>
			</xsl:if>
			<xsl:for-each select="Item">
			<LIN>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="Details/LineNum" />
				</Field>
				<Field>
					<xsl:value-of select="Details/ItemStatus" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="Details/BuyersItemNum" />
					</Field>
					<Field>IN</Field>
				</Field>
			</LIN>
			<xsl:if test="string-length(Details/ProductFunction) &gt; 0">
			<PIA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="Details/ProductFunction" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="Details/ProductID" />
					</Field>
					<Field>
						<xsl:value-of select="Details/ProductType" />
					</Field>
				</Field>
			</PIA>
			</xsl:if>
			<xsl:if test="string-length(Details/Description) &gt; 0">
			<IMD>
				<mapper:incVar name="segmentCount" />
				<Field/>
				<Field/>
				<Field>
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="Details/Description" />
					</Field>
				</Field>
			</IMD>
			</xsl:if>
			<QTY>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>12</Field>
					<Field>
						<xsl:value-of select="Details/DespatchQty" />
					</Field>
					<Field>
						<xsl:value-of select="Details/DespatchQtyUOM" />
					</Field>
				</Field>
			</QTY>
			<xsl:if test="string-length(Details/CountryOfOrigin) &gt; 0">
			<ALI>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="Details/CountryOfOrigin" />
				</Field>
			</ALI>
			</xsl:if>
			<xsl:if test="string-length(Details/SerialNum) &gt; 0">
			<GIN>
				<mapper:incVar name="segmentCount" />
				<Field>GN</Field>
				<Field>
					<Field>
						<xsl:value-of select="Details/SerialNum" />
					</Field>
				</Field>
			</GIN>
			</xsl:if>
			<xsl:if test="string-length(Details/CustomerRefNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CN</Field>
					<Field>
						<xsl:value-of select="Details/CustomerRefNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="Details/PONum" />
					</Field>
				</Field>
			</RFF>
			<xsl:if test="string-length(Details/PackingListNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>PK</Field>
					<Field>
						<xsl:value-of select="Details/PackingListNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(Details/ReleaseNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>RE</Field>
					<Field>
						<xsl:value-of select="Details/ReleaseNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(Details/MarkingLabelRef) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>AFF</Field>
					<Field>
						<xsl:value-of select="Details/MarkingLabelRef" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(Details/ConveyanceRefNumber) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CRN</Field>
					<Field>
						<xsl:value-of select="Details/ConveyanceRefNumber" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			</xsl:for-each> <!--End of Item Loop-->
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