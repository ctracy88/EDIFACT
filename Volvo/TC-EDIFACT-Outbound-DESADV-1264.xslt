<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML ASN into a specific Volvo EANCOM D00A ASN.
	
	Input: Generic XML ASN.
	Output: Volvo EANCOM D00A DESADV.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: July 22, 2016
	
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
			</BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="DTM/TransCreateDate" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
			<xsl:if test="string-length(MEA/TotalGrossWeight) &gt; 0">
			<MEA>
				<mapper:incVar name="segmentCount" />
				<Field>AAX</Field>
				<Field>AAD</Field>
				<Field>
					<Field>
						<xsl:value-of select="MEA/TotalGrossWeightUOM" />
					</Field>
					<Field>
						<xsl:value-of select="MEA/TotalGrossWeight" />
					</Field>
				</Field>
			</MEA>
			</xsl:if>
			<xsl:if test="string-length(MEA/Volume) &gt; 0">
			<MEA>
				<mapper:incVar name="segmentCount" />
				<Field>AAX</Field>
				<Field>ABJ</Field>
				<Field>
					<Field>
						<xsl:value-of select="MEA/VolumeUOM" />
					</Field>
					<Field>
						<xsl:value-of select="MEA/Volume" />
					</Field>
				</Field>
			</MEA>
			</xsl:if>
			<xsl:if test="string-length(RFF/TransportDocNum) &gt; 0">
            <RFF>
				<mapper:incVar name="segmentCount" />
				<Field>AAS</Field>
				<Field>
					<xsl:value-of select="RFF/TransportDocNum" />
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/AirwaybillNum) &gt; 0">
            <RFF>
				<mapper:incVar name="segmentCount" />
				<Field>AWB</Field>
				<Field>
					<xsl:value-of select="RFF/AirwaybillNum" />
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/BOLNum) &gt; 0">
            <RFF>
				<mapper:incVar name="segmentCount" />
				<Field>BM</Field>
				<Field>
					<xsl:value-of select="RFF/BOLNum" />
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/CustomerRefNum) &gt; 0">
            <RFF>
				<mapper:incVar name="segmentCount" />
				<Field>CR</Field>
				<Field>
					<xsl:value-of select="RFF/CustomerRefNum" />
				</Field>
			</RFF>
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.ST/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.ST/CodeType" />
					</Field>
				</Field>
				<LOC>
					<mapper:incVar name="segmentCount" />
					<Field>7</Field>
					<Field>
						<xsl:value-of select="NAD.ST/LOC/PortOfDischarge" />
					</Field>
				</LOC>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SE</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SE/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.SE/CodeType" />
					</Field>
				</Field>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>CA</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.CA/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.CA/CodeType" />
					</Field>
				</Field>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.SF/CodeType" />
					</Field>
				</Field>
			</NAD>
			<TDT>
                <mapper:incVar name="segmentCount" />
                <Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
                <Field/>
                <Field/>
                <Field>
					<xsl:value-of select="TDT/MeansOfTransport" />
				</Field>
            </TDT>
			<xsl:for-each select="Pack">
				<CPS>
					<mapper:incVar name="segmentCount" />
					<mapper:incVar name="packageIncrementer" />
					<mapper:setVar name="currentPackage">
						<mapper:getVar name="packageIncrementer" />
					</mapper:setVar>
					<Field>
						<mapper:getVar name="packageIncrementer" />
					</Field>
				</CPS>
				<PAC>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="PAC/NumOfPackages" />
					</Field>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="PAC/RefNum" />
						</Field>
						<Field/>
						<Field>92</Field>
					</Field>
				</PAC>
				<QTY>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>52</Field>
						<Field>
							<xsl:value-of select="QTY/QtyPerPack" />
						</Field>
						<Field>C62</Field>
					</Field>
				</QTY>
				<PCI>
					<mapper:incVar name="segmentCount" />
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="PCI/MarkInstr" />
						</Field>
						<Field/>
						<Field>
							<xsl:value-of select="PCI/PackagingCode" />
						</Field>
					</Field>
				</PCI>
				<xsl:if test="string-length(RFF/OuterPackUnitID) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>ACI</Field>
						<Field>
							<xsl:value-of select="RFF/OuterPackUnitID" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<GIR>
					<mapper:incVar name="segmentCount" />
					<Field>1</Field>
					<Field>
						<Field>
							<xsl:value-of select="GIR/BatchNum" />
						</Field>
						<Field>BX</Field>
					</Field>
				</GIR>
				<GIN>
					<mapper:incVar name="segmentCount" />
					<Field>ML</Field>
					<Field>
						<xsl:value-of select="GIR/LabelNum" />
					</Field>
				</GIN>
				<xsl:for-each select="Item">
				<LIN>
					<mapper:incVar name="segmentCount" />
					<Field/>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="Details/BuyersItemNum" />
						</Field>
						<Field>IN</Field>
					</Field>
				</LIN>
				<xsl:if test="string-length(Details/DrawingRevNum) &gt; 0">
				<PIA>
					<mapper:incVar name="segmentCount" />
					<Field>1</Field>
					<Field>
						<Field>
							<xsl:value-of select="Details/DrawingRevNum" />
						</Field>
						<Field>DR</Field>
					</Field>
				</PIA>
				</xsl:if>
				<QTY>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>12</Field>
						<Field>
							<xsl:value-of select="Details/DespatchQty" />
						</Field>
						<Field>G62</Field>
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
					<Field>BN</Field>
					<Field>
						<xsl:value-of select="Details/SerialNum" />
					</Field>
				</GIN>
				</xsl:if>
				<xsl:if test="string-length(Details/EngineNum) &gt; 0">
				<GIN>
					<mapper:incVar name="segmentCount" />
					<Field>EE</Field>
					<Field>
						<xsl:value-of select="Details/EngineNum" />
					</Field>
				</GIN>
				</xsl:if>
				<xsl:if test="string-length(Details/VINNum) &gt; 0">
				<GIN>
					<mapper:incVar name="segmentCount" />
					<Field>VV</Field>
					<Field>
						<xsl:value-of select="Details/VINNum" />
					</Field>
				</GIN>
				</xsl:if>
				<xsl:if test="string-length(Details/CustomsValue) &gt; 0">
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>40</Field>
					<Field>
						<xsl:value-of select="Details/CustomsValue" />
					</Field>
					<Field>EUR</Field>
				</MOA>
				</xsl:if>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="Details/OrderNum" />
					</Field>
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>IV</Field>
					<Field>
						<xsl:value-of select="Details/InvoiceNum" />
					</Field>
					<DTM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>171</Field>
							<Field>
								<xsl:value-of select="Details/InvoiceDate" />
							</Field>
							<Field>102</Field>
						</Field>
					</DTM>
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>AAP</Field>
					<Field>
						<xsl:value-of select="Details/PartConsignmentNum" />
					</Field>
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>CR</Field>
					<Field>
						<xsl:value-of select="Details/CustRefNum" />
					</Field>
				</RFF>
				<LOC>
					<mapper:incVar name="segmentCount" />
					<Field>159</Field>
					<Field>
						<Field>
							<xsl:value-of select="Details/AdditionalDestination" />
						</Field>
						<Field/>
						<Field>92></Field>
					</Field>
				</LOC>
				</xsl:for-each> <!--End of Item Loop-->
			</xsl:for-each> <!--End of Pack Loop-->
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