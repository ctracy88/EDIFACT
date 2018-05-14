<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML ASN into a specific Volvo EANCOM D96A ASN.
	
	Input: Generic XML ASN.
	Output: Volvo EANCOM D96A DESADV.
	
	Author: Jennifer Ciambro	
	Version: 1.0
	Creation Date: 04-18-2017
	
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
                <Field>
                <!-- Processing Priority -->
                </Field>
                <Field>
                <!-- Acknowledgement Request -->
                </Field>
                <Field>
                <!-- Communications Agreement -->
                </Field>
                <Field>
                <!-- Space -->
                </Field>
                <Field>
					<xsl:value-of select="/Batch/ASN[1]/BatchReferences/test" />
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
					<xsl:value-of select="UNH/ControlAgencySuffix" />
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
                        <xsl:value-of select="concat(DTM/TransCreateDate,DTM/DocTime)" />
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
				<Field>
					<Field>AAS</Field>
					<Field>
						<xsl:value-of select="RFF/TransportDocNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/AirwaybillNum) &gt; 0">
            <RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CRN</Field>
					<Field>
						<xsl:value-of select="RFF/AirwaybillNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>CZ</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.CZ/Code" />
                    </Field>
                    <Field></Field>
                    <Field>92</Field>
				</Field>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SE</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SE/Code" />
                    </Field>
                    <Field></Field>
                    <Field>92</Field>
				</Field>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>CN</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.CN/Code" />
                    </Field>
                    <Field></Field>
                    <Field>92</Field>
				</Field>
				<LOC>
					<mapper:incVar name="segmentCount" />
					<Field>11</Field>
					<Field>
						<Field>
							<xsl:value-of select="NAD.CN/LOC.NAD.CN/ConsigneePortDischarge" />
						</Field>
						<Field/>
						<Field>92</Field>
					</Field>
				</LOC>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>CA</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.CA/Code" />
                    </Field>
                    <Field></Field>
                    <Field>92</Field>
				</Field>
			</NAD>
				<xsl:for-each select="Order">
				<CPS>
					<mapper:incVar name="segmentCount" />
					<mapper:incVar name="packageIncrementer" />
					<mapper:setVar name="currentPackage">
						<mapper:getVar name="packageIncrementer" />
					</mapper:setVar>
					<Field>
						<mapper:getVar name="packageIncrementer" />
					</Field>
					<Field/>
					<Field>1</Field>
				</CPS>
				<PAC>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="TotalCartons" />
					</Field>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="PackageRefNum" />
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
							<xsl:value-of select="QtyPerPack" />
						</Field>
						<Field>
							<xsl:value-of select="QtyPerPackUOM" />
						</Field>
					</Field>
				</QTY>
				<PCI>
					<mapper:incVar name="segmentCount" />
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="MarkInstr" />
						</Field>
						<Field/>
						<Field>
							<xsl:value-of select="PackagingCode" />
						</Field>
					</Field>
				</PCI>
				<xsl:if test="string-length(MasterLabelNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>AAT</Field>
						<Field>
							<xsl:value-of select="MasterLabelNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
					 <xsl:for-each select="OrderPack">
					<GIR>
						<mapper:incVar name="segmentCount" />
						<Field>3</Field>
						<Field>
							<Field>
								<xsl:value-of select="PackagingID" />
							</Field>
							<Field>ML</Field>
						</Field>
						<Field>
							<Field>
								<xsl:value-of select="PackagingIDType" />
							</Field>
							<Field>BX</Field>
						</Field>
					</GIR>
						<xsl:for-each select="OrderPackItems">
						<xsl:if test="string-length(BuyersItemNum) &gt; 0">
						<LIN>
							<mapper:incVar name="segmentCount" />
							<Field/>
							<Field/>
							<Field>
								<Field>
									<xsl:value-of select="BuyersItemNum" />
								</Field>
								<Field>IN</Field>
							</Field>
							<Field/>
							<Field>0</Field>
						</LIN>
						</xsl:if>
						<xsl:if test="string-length(DrawingRevNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
									<xsl:value-of select="DrawingRevNum" />
								</Field>
								<Field>DR</Field>
							</Field>
						</PIA>
						</xsl:if>
						<xsl:if test="string-length(DespatchQty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>12</Field>
								<Field>
									<xsl:value-of select="DespatchQty" />
								</Field>
								<Field>
									<xsl:value-of select="DespatchQtyUOM" />
								</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(CountryOfOrigin) &gt; 0">
						<ALI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="CountryOfOrigin" />
							</Field>
						</ALI>
						</xsl:if>
						<xsl:if test="string-length(SerialNum) &gt; 0">
						<GIN>
							<mapper:incVar name="segmentCount" />
							<Field>BN</Field>
							<Field>
								<xsl:value-of select="SerialNum" />
							</Field>
						</GIN>
						</xsl:if>
						<xsl:if test="string-length(EngineNum) &gt; 0">
						<GIN>
							<mapper:incVar name="segmentCount" />
							<Field>EE</Field>
							<Field>
								<xsl:value-of select="EngineNum" />
							</Field>
						</GIN>
						</xsl:if>
						<xsl:if test="string-length(VINNum) &gt; 0">
						<GIN>
							<mapper:incVar name="segmentCount" />
							<Field>VV</Field>
							<Field>
								<xsl:value-of select="VINNum" />
							</Field>
						</GIN>
						</xsl:if>
						<xsl:if test="string-length(CustomsValue) &gt; 0">
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>40</Field>
							<Field>
								<xsl:value-of select="CustomsValue" />
							</Field>
							<Field>
								<xsl:value-of select="CustomsValueUOM" />
							</Field>
						</MOA>
						</xsl:if>
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>ON</Field>
								<Field>
									<xsl:value-of select="PONum" />
								</Field>
							</Field>
						</RFF>
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>IV</Field>
								<Field>
									<xsl:value-of select="InvoiceNum" />
								</Field>
							</Field>
							<DTM>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>171</Field>
									<Field>
										<xsl:value-of select="InvoiceDate" />
									</Field>
									<Field>102</Field>
								</Field>
							</DTM>
						</RFF>
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAP</Field>
								<Field>
									<xsl:value-of select="PartConsignmentNum" />
								</Field>
							</Field>
						</RFF>
						<xsl:if test="string-length(CertificateNum) &gt; 0">
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AEE</Field>
								<Field>
									<xsl:value-of select="CertificateNum" />
								</Field>
							</Field>
						</RFF>
						</xsl:if>
						<xsl:if test="string-length(AdditionalInternalDest) &gt; 0">
						<LOC>
							<mapper:incVar name="segmentCount" />
							<Field>159</Field>
							<Field>
								<Field>
									<xsl:value-of select="AdditionalInternalDest" />
								</Field>
								<Field/>
								<Field>92</Field>
							</Field>
						</LOC>
						</xsl:if>
						<xsl:if test="string-length(PortOfDischarge) &gt; 0">
						<LOC>
							<mapper:incVar name="segmentCount" />
							<Field>11</Field>
							<Field>
								<Field>
									<xsl:value-of select="PortOfDischarge" />
								</Field>
								<Field/>
							</Field>
						</LOC>
						</xsl:if>
				</xsl:for-each> <!--End of CartonItems Loop-->
				</xsl:for-each><!--End of Carton Loop-->
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
</xsl:stylesheet>