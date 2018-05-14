<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML INVOIC into a Cummins D97A Invoice.
	
	Input: Generic XML Invoice.
	Output: Cummins D97A Invoice.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: August 3, 2016
		
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
		
		<xsl:variable name="receiverANA" select="/Batch/Invoice[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/Invoice[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
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
                <xsl:value-of select="'1'" />
            </xsl:attribute>
            <mapper:setVar name="messageCount">0</mapper:setVar> <!-- Segment counter do not remove -->
            <UNB>
                <Field> <!-- UNB 1-->
                    <Field>UNOA</Field> <!-- UNB 1.1-->
                    <Field>1</Field> <!-- UNB 1.2-->
                </Field>
                <Field> <!-- UNB 2-->
                    <Field> <!-- UNB 2.1-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field> <!-- UNB 2.2-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/Location" />
                    </Field>
                    <Field>1</Field>
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
                    <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field>INVOIC</Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field /> <!-- UNB 9 -->
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="Batch/Invoice[1]/BatchReferences/test" />
                </Field>
                <xsl:apply-templates select="Invoice">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="Invoice">
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
				<Field> <!-- UNH 2.5 -->
					<xsl:value-of select="UNH/AssociationCode" />
				</Field>
				<Field/> <!-- UNH 2.6 -->
				<Field/> <!-- UNH 2.7 -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field> <!-- BGM 1 -->
                    <Field> <!-- BGM 1.1 -->
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
                    <Field/> <!-- BGM 1.2 -->
                    <Field/> <!-- BGM 1.3-->
					<Field/> <!-- BGM 1.4 -->
				</Field>
                <Field> <!-- BGM 2 -->
                    <xsl:value-of select="BGM/DocNum" />
                </Field>
                <Field> <!-- BGM 3 -->
					<xsl:value-of select="BGM/MsgFunction" />
				</Field>
			</BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>3</Field>
                    <Field>
                        <xsl:value-of select="DTM/InvoiceDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>140</Field>
                    <Field>
						<xsl:value-of select="DTM/PaymentDueDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAI</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/Note" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(RFF/ShippingBOL) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>BM</Field>
                    <Field>
                        <xsl:value-of select="RFF/ShippingBOL" />
                    </Field>
                 </Field>
				 <DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>95</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/BOLDate" />
						</Field>
						<Field>102</Field>
					</Field>
				 </DTM>
			</RFF>
            </xsl:if>
			<xsl:if test="string-length(RFF/ShippingCarPro) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>CN</Field>
                    <Field>
                        <xsl:value-of select="RFF/ShippingCarPro" />
                    </Field>
                 </Field>
			</RFF>
            </xsl:if>
			<xsl:if test="string-length(RFF/ExporterLicense) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>EX</Field>
                    <Field>
                        <xsl:value-of select="RFF/ExporterLicense" />
                    </Field>
                 </Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/ImportLicense) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>IP</Field>
                    <Field>
                        <xsl:value-of select="RFF/ImportLicense" />
                    </Field>
                 </Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/LetterOfCredit) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>LC</Field>
                    <Field>
                        <xsl:value-of select="RFF/LetterOfCredit" />
                    </Field>
                 </Field>
			</RFF>
			</xsl:if>
			<RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>ON</Field>
                    <Field>
                        <xsl:value-of select="RFF/PONum" />
                    </Field>
                 </Field>
			</RFF>
			<xsl:if test="string-length(RFF/PackingListNum) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>PK</Field>
                    <Field>
                        <xsl:value-of select="RFF/PackingListNum" />
                    </Field>
                 </Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/TransportDocNum) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>AEX</Field>
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
                    <Field>AWB</Field>
                    <Field>
                        <xsl:value-of select="RFF/AirwaybillNum" />
                    </Field>
                 </Field>
				 <DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>22</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/FreightBillDate" />
						</Field>
						<Field>102</Field>
					</Field>
				 </DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/ShipmentRefNum) &gt; 0">
            <RFF>
                 <mapper:incVar name="segmentCount" />
                 <Field>
                    <Field>SRN</Field>
                    <Field>
                        <xsl:value-of select="RFF/ShipmentRefNum" />
                    </Field>
                 </Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(NAD.BY/Code) &gt; 0">
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <!-- BY = Buyer -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.BY/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.BY/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/Country" />
				</Field>
            </NAD>
            </xsl:if>
            <xsl:if test="string-length(NAD.SE/Code) &gt; 0">
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SE</Field>
                <!-- SE = Seller -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SE/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.SE/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.SE/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SE/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SE/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/State" /> 
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/Country" />
				</Field>
			</NAD>
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
                <!-- ST = Ship To -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.ST/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.ST/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.ST/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.ST/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.ST/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/Country" />
				</Field>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <!-- SF = Ship From -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="NAD.SF/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.SF/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SF/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SF/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/Country" />
				</Field>
			</NAD>
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>1</Field>
					<Field>
						<xsl:value-of select="CUX/Currency" />
					</Field>
				</Field>
			</CUX>
			<PAT>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PAT/Type" />
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="PAT/BasedOn" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/TimeRelation" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/TypeOfPeriod" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/NumOfPeriods" />
					</Field>
				</Field>
			</PAT>
			<xsl:if test="string-length(TDT/ConveyanceRefNum) &gt; 0">
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
					<xsl:if test="string-length(TDT/SCAC) &gt; 0">
					<Field>172</Field>
					<Field>182</Field>
					</xsl:if>
					<Field>
						<xsl:value-of select="TDT/ShippingRouting" />
					</Field>
				</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="TDT/VoyageNum" />
					</Field>
					<Field>
						<xsl:value-of select="TDT/VesselName" />
					</Field>
				</Field>
			</TDT>
			</xsl:if>
			<LOC>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="LOC/LocationType" />
				</Field>
				<Field>
					<xsl:value-of select="LOC/Location" />
				</Field>
				<xsl:if test="string-length(LOC/DTM/DespatchDate) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>11</Field>
						<Field>
							<xsl:value-of select="LOC/DTM/DespatchDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				</xsl:if>
				<xsl:if test="string-length(LOC/DTM/EstimatedArrivalDate) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>132</Field>
						<Field>
							<xsl:value-of select="LOC/DTM/EstimatedDepartureDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				</xsl:if>
				<xsl:if test="string-length(LOC/DTM/EstimatedDepartureDate) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>133</Field>
						<Field>
							<xsl:value-of select="LOC/DTM/EstimatedArrivalDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				</xsl:if>
			</LOC>
			<PAC>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PAC/NumOfPackages" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="PAC/PackagingLevel" />
					</Field>
				</Field>
				<Field>
					<Field>F</Field>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="PAC/PackageType" />
					</Field>
				</Field>
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>WT</Field>
					<Field>
						<Field>G</Field>
					</Field>
					<Field>
						<Field>KGM</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/GrossWeight" />
						</Field>
					</Field>
				</MEA>
				<xsl:if test="string-length(PAC/MEA/NetWeight) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>WT</Field>
					<Field>
						<Field>N</Field>
					</Field>
					<Field>
						<Field>KGM</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/NetWeight" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
				<xsl:if test="string-length(PAC/MEA/Height) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>AAE</Field>
					<Field>
						<Field>HT</Field>
					</Field>
					<Field>
						<Field>CMT</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/Height" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
				<xsl:if test="string-length(PAC/MEA/Length) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>AAE</Field>
					<Field>
						<Field>LN</Field>
					</Field>
					<Field>
						<Field>CMT</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/Length" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
				<xsl:if test="string-length(PAC/MEA/Width) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>AAE</Field>
					<Field>
						<Field>WD</Field>
					</Field>
					<Field>
						<Field>CMT</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/Width" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
				<xsl:if test="string-length(PAC/MEA/Volume) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>AAE</Field>
					<Field>
						<Field>ABJ</Field>
					</Field>
					<Field>
						<Field>CMT</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/Volume" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
				<xsl:if test="string-length(PAC/EQD/EqupimentQual) &gt; 0">
				<EQD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="PAC/EQD/EquipmentQual" />
					</Field>
					<Field>
						<xsl:value-of select="PAC/EQD/EquipmentNum" />
					</Field>
				</EQD>
				</xsl:if>
			</PAC>
			<PCI>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PCI/MarkInstr" />
				</Field>
				<xsl:if test="string-length(PCI/RFF/ContainerOpRefNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>CV</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/ContainerOpRefNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(PCI/RFF/PackingListNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>PK</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/PackingListNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(PCI/RFF/SealNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>SN</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/SealNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(PCI/RFF/GoodsDeclarationNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>AAE</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/GoodsDeclarationNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(PCI/RFF/MasterLabelNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>AAT</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/MasterLabelNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(PCI/RFF/MarkingLabelRef) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>AFF</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/MarkingLabelRef" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(PCI/RFF/HouseWaybillNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>HWB</Field>
						<Field>
							<xsl:value-of select="PCI/RFF/HouseWaybillNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
			</PCI>
			<xsl:for-each select="Item">
				<LIN>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="LIN/LineNum" />
					</Field>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="LIN/ItemNumber" />
						</Field>
						<Field>
							<xsl:value-of select="LIN/ItemNumberType" />
						</Field>
					</Field>
					<xsl:if test="string-length(LIN/PIA/Assembly) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/Assembly" />
							</Field>
							<Field>AB</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/UPCContainerCode) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/UPCContainerCode" />
							</Field>
							<Field>AL</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/CommodityGrouping) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/CommodityGrouping" />
							</Field>
							<Field>CG</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/CustomsArticleNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/CustomsArticleNum" />
							</Field>
							<Field>CV</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/ItemModelNumber) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/ItemModelNumber" />
							</Field>
							<Field>MN</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/ProductIDNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/ProductIDNum" />
							</Field>
							<Field>MP</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/CustomerOrderNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/CustomerOrderNum" />
							</Field>
							<Field>ON</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/ItemPONum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/ItemPONum" />
							</Field>
							<Field>PO</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/PIA/TransportGroupNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/PIA/TransportGroupNum" />
							</Field>
							<Field>TG</Field>
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
					<xsl:if test="string-length(LIN/IMD/Desc) &gt; 0">
					<IMD>
						<mapper:incVar name="segmentCount" />
						<Field>F</Field>
						<Field/>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/Desc" />
							</Field>
						</Field>
					</IMD>
					</xsl:if>
					<xsl:if test="string-length(LIN/MEA/Measurement) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>AAE</Field>
						<Field/>
						<Field>
							<Field>
								<xsl:value-of select="LIN/IMD/MeasurementUOM" />
							</Field>
							<Field>
								<xsl:value-of select="LIN/IMD/Measurement" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<QTY>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>47</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/Qty" />
							</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/UOM" />
							</Field>
						</Field>
					</QTY>
					<xsl:if test="string-length(LIN/ALI/CountryOfOrigin) &gt; 0">
					<ALI>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/ALI/CountryOfOrigin" />
						</Field>
					</ALI>
					</xsl:if>
					<xsl:if test="string-length(LIN/GIN/EngineNum) &gt; 0">
					<GIN>
						<mapper:incVar name="segmentCount" />
						<Field>BN</Field>
						<Field>
							<xsl:value-of select="LIN/GIN/EngineNum" />
						</Field>
					</GIN>
					</xsl:if>
					<xsl:if test="string-length(LIN/GIN/InvoiceNum) &gt; 0">
					<GIN>
						<mapper:incVar name="segmentCount" />
						<Field>BS</Field>
						<Field>
							<xsl:value-of select="LIN/GIN/InvoiceNum" />
						</Field>
					</GIN>
					</xsl:if>
					<MOA>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>203</Field>
							<Field>
								<xsl:value-of select="LIN/MOA/ItemExtendedNetAmount" />
							</Field>
						</Field>
					</MOA>
					<PRI>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>INV</Field>
							<Field>
								<xsl:value-of select="LIN/PRI/Price" />
							</Field>
						</Field>
					</PRI>
					<PAC>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/PAC/NumOfPackages" />
						</Field>
						<Field>1</Field>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/PAC/PackageType" />
							</Field>
						</Field>
						<xsl:if test="string-length(LIN/PAC/MEA/ItemGrossWeight) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>WT</Field>
							<Field>G</Field>
							<Field>
								<Field>KGM</Field>
								<Field>
									<xsl:value-of select="LIN/PAC/MEA/ItemGrossWeight" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PAC/MEA/ItemNetWeight) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>WT</Field>
							<Field>N</Field>
							<Field>
								<Field>KGM</Field>
								<Field>
									<xsl:value-of select="LIN/PAC/MEA/ItemNetWeight" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PAC/MEA/ItemHeight) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>AAE</Field>
							<Field>HT</Field>
							<Field>
								<Field>CMT</Field>
								<Field>
									<xsl:value-of select="LIN/PAC/MEA/ItemHeight" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PAC/MEA/ItemLength) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>AAE</Field>
							<Field>LN</Field>
							<Field>
								<Field>CMT</Field>
								<Field>
									<xsl:value-of select="LIN/PAC/MEA/ItemLength" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PAC/MEA/ItemWidth) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>AAE</Field>
							<Field>WD</Field>
							<Field>
								<Field>CMT</Field>
								<Field>
									<xsl:value-of select="LIN/PAC/MEA/ItemWidth" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PAC/MEA/ItemVolume) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>AAE</Field>
							<Field>ABJ</Field>
							<Field>
								<Field>CMT</Field>
								<Field>
									<xsl:value-of select="LIN/PAC/MEA/ItemVolume" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<PCI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/PAC/PCI/ItemMarkInstr" />
							</Field>
							<xsl:if test="string-length(LIN/PAC/PCI/RFF/ItemMarkLabelRef) &gt; 0">
							<RFF>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>AFF</Field>
									<Field>
										<xsl:value-of select="LIN/PAC/PCI/RFF/ItemMarkLabelRef" />
									</Field>
								</Field>
							</RFF>
							</xsl:if>
						</PCI>
					</PAC>
					<xsl:if test="string-length(LIN/NAD.ST/ItemShipToName) &gt; 0">
					<NAD>
							<mapper:incVar name="segmentCount" />
							<Field>ST</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/NAD.ST/Code" />
								</Field>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/NAD.ST/CodeType" />
								</Field>
							</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/NAD.ST/Name" />
							</Field>
					</NAD>
					</xsl:if>
				</LIN>
			</xsl:for-each>
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>39</Field>
					<Field>
						<xsl:value-of select="MOA/InvoiceTotalAmount" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>77</Field>
					<Field>
						<xsl:value-of select="MOA/InvoiceAmount" />
					</Field>
				</Field>
			</MOA>
			<xsl:if test="string-length(TAX/VATRate) &gt; 0">
			<TAX>
				<mapper:incVar name="segmentCount" />
				<Field>7</Field>
				<Field>VAT</Field>
				<Field/>
				<Field/>
				<Field>
					<Field/>
					<Field/>
					<Field>109</Field>
					<Field>
						<xsl:value-of select="TAX/VATRate" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="TAX/VATIdNum" />
				</Field>
				<xsl:if test="string-length(TAX/MOA/VATAmt) &gt; 0">
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>150</Field>
						<Field>
							<xsl:value-of select="TAX/MOA/VATAmt" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</TAX>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/ExportShippingCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>EX</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/ExportShippingCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/FreightCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>FC</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/FreightCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/InsuranceCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>IN</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/InsuranceCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/PalletCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>PN</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/PalletCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/InlandTransportationCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>ADD</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/InlandTransportationCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/CartageCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>CAB</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/CartageCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/ShippingHandlingCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>SAA</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/ShippingHandlingCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/SpecialPackagingCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>SAD</Field>
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/SpecialPackagingCharge" />
						</Field>
					</Field>
				</MOA>
			</ALC>
			</xsl:if>
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