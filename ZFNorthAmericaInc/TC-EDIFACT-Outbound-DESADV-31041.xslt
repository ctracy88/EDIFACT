<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Summit Polymers DESADV from TC XML into a Summit Polymers D97A DESADV.
	
	Input: Generic XML Invoice.
	Output: Tesco EANCOM D96A Invoice.
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: March 27, 2017
	
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
        <Document type="EDIFACT" wrapped="true">
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
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field>
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
                        <xsl:value-of select="DTM/ShipmentDate" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
						<xsl:value-of select="DTM/IssueDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>132</Field>
                    <Field>
						<xsl:value-of select="DTM/EstimatedArrivalDate" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
			<MEA>
				<mapper:incVar name="segmentCount" />
				<Field>AAX</Field>
				<Field>G</Field>
				<Field>
					<Field>KGM</Field>
					<Field>
						<xsl:value-of select="MEA/GrossWeight" />
					</Field>
				</Field>
			</MEA>
			<MEA>
				<mapper:incVar name="segmentCount" />
				<Field>AAX</Field>
				<Field>N</Field>
				<Field>
					<Field>KGM</Field>
					<Field>
						<xsl:value-of select="MEA/NetWeight" />
					</Field>
				</Field>
			</MEA>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>MI</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.MI/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.MI/CodeType" />
					</Field>
                </Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.MI/Name" />
					</Field>
				</Field>
            </NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.SU/CodeType" />
					</Field>
                </Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Name" />
					</Field>
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
					<Field>
						<xsl:value-of select="NAD.ST/Name" />
					</Field>
				</Field>
				<LOC>
					<Field>11</Field>
					<Field>
						<Field>
							 <xsl:value-of select="LOC.NADST/DockNum" />
						</Field>
						<Field></Field>
						<Field></Field>
						<Field>
							 <xsl:value-of select="LOC.NADST/DockName" />
						</Field>
					</Field>
				</LOC>
				<LOC>
					<Field>159</Field>
					<Field>
						<Field>
							 <xsl:value-of select="LOC.NADST/AdditionalInternalDestination" />
						</Field>
						<Field></Field>
						<Field></Field>
						<Field></Field>
					</Field>
				</LOC>
            </NAD>
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
					<Field>
						<xsl:value-of select="NAD.SF/Name" />
					</Field>
				</Field>
            </NAD>
			<TDT>
                <mapper:incVar name="segmentCount" />
                <Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
                <Field/>
				<Field>
					<Field>
						<xsl:value-of select="TDT/ModeOfTransport" />
					</Field>
				</Field>
                <Field/>
				<Field>
					<Field>
						<xsl:value-of select="TDT/SCAC" />
					</Field>
					<Field/>
					<Field>92</Field>
					<Field></Field>
				</Field>
			</TDT>
			<xsl:if test="string-length(EQD/EquipmentNum) &gt; 0">
            <EQD>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="EQD/EquipmentQual" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="EQD/EquipmentNum" />
					</Field>
				</Field>		
			</EQD>
			</xsl:if>
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
					<Field/>
					<Field>4</Field>
				</CPS>
				<PAC>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="NumOfPackages" />
					</Field>
					</Field>
					<Field>
						<xsl:value-of select="PackageType" />
					</Field>
					<Field>
						<Field></Field>
						<Field>
							<xsl:value-of select="PackBuyerItemNum" />
						</Field>
						<Field>IN</Field>
						<Field>
							<xsl:value-of select="PackSupplierItemNum" />
						</Field>
						<Field>SA</Field>
					</Field>
					<QTY>
						<Field>
							<Field>52</Field>
							<Field>
								<xsl:value-of select="QtyPerPack" />
							</Field>
							<Field>C62</Field>
						</Field>
					</QTY>
					<PCI>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="MarkInstr" />
						</Field>
						</Field>
						</Field>
						<Field>
							<xsl:value-of select="MarkingType" />
						</Field>
					</PCI>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>AAT</Field>
							<Field>
								<xsl:value-of select="MasterLabelNum" />
							</Field>
						</Field>
					</RFF>
					<GIR>
						<Field>3</Field>
						<Field>
							<Field>
								<xsl:value-of select="MarkingLabelNum" />
							</Field>
							<Field>ML</Field>
						</Field>
						<Field>
							<Field>
								<xsl:value-of select="BatchNum" />
							</Field>
							<Field>BX</Field>
						</Field>
						<Field>
							<Field>
								<xsl:value-of select="NestNum" />
							</Field>
							<Field>NE</Field>
						</Field>
					</GIR>
				</PAC>
				<xsl:for-each select="Item">
				<LIN>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="LIN/LinNum" />
					<Field/>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="LIN/BuyersItemNum" />
						</Field>
						<Field>IN</Field>
					</Field>
					<xsl:if test="string-length(LIN/PIA) &gt; 0">
					<PIA>
						<Field>1</Field>
						<Field>
							<Field>
							<xsl:value-of select="LIN/PIA/SupplierItemNum" />
							</Field>
							<Field>SA</Field>
						</Field>
						<Field>
							<Field>
							<xsl:value-of select="LIN/PIA/EngineeringChangeLvl" />
							</Field>
							<Field>EC</Field>
						</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(LIN/IMD/Description) &gt; 0">
					<IMD>
						</Field>
						</Field>
						<Field>
							<Field></Field>
							<Field></Field>
							<Field></Field>
							<Field>
								<xsl:value-of select="LIN/IMD/Description" />
							</Field>
						</Field>
					</IMD>
					</xsl:if>
					<xsl:if test="string-length(LIN/QTY/DespatchQty) &gt; 0">
					<QTY>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>12</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/DespatchQty" />
							</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/DespatchQtyUOM" />
							</Field>
						</Field>
					</QTY>
					</xsl:if>
					<xsl:if test="string-length(LIN/ALI/CountryOfOrigin) &gt; 0">
					<ALI>
						<Field>
							<xsl:value-of select="LIN/ALI/CountryOfOrigin" />
						</Field>
					</ALI>
					</xsl:if>
					<xsl:if test="string-length(LIN/FTX/ItemNote) &gt; 0">
					<FTX>
						<Field>AAI</Field>
						</Field>
						</Field>
						<Field>
							<xsl:value-of select="LIN/FTX/ItemNote" />
						</Field>
					</FTX>
					</xsl:if>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>ON</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/OrderNum" />
							</Field>
						</Field>
					</RFF>	
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>AAK</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/DespatchAdviceNum" />
							</Field>
						</Field>
					</RFF>					
				</LIN>
				</xsl:for-each>
			</xsl:for-each>
			<UNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <mapper:getVar name="segmentCount" />
                </Field>
				<Field>
                    <xsl:value-of select="$MsgRefNum" />
                </Field>
            </UNT>
        </UNH>
    </xsl:template>
    <!--
			Template used to determine if a product is stored in a box or a green tray for Tesco -->
		
		<xsl:template name="determine-product-case-type"><xsl:param name="name" /></xsl:template></xsl:stylesheet>