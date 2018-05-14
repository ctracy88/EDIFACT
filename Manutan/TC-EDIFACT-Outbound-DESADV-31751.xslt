<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML into The Iconic D01B DESADV.
	
	Input: TC XML.
	Output: CThe Iconic D01B DESADV.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: August 25, 2016
	
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
        <Document una=":+.? '" type="EDIFACT" wrapped="false">
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
                    <Field>UNOC</Field>
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
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/GSReceiverCode" />
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
                <Field></Field>
                <Field />
                <!-- Processing Priority -->
                <Field>1</Field>
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
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
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
                <Field>D</Field>
                <Field>96A</Field>
                <Field>
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
                <Field>EAN005</Field>
			</Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
					<Field>351</Field>
					<Field>
						<xsl:value-of select="BGM/DocNum" />
					</Field>
					<Field>9</Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="DTM/DocDate" />
                    </Field>
                    <Field>204</Field>
                </Field>
            </DTM>
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>17</Field>
                    <Field>
                        <xsl:value-of select="DTM/ShipmentDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
            <MEA>
				<mapper:incVar name="segmentCount" />
				<Field>WT</Field>
				<Field></Field>
				<Field>
					<Field>KGM</Field>
					<Field>
                        <xsl:value-of select="MEA/TotalGrossWeight" />
                    </Field>
				</Field>
            </MEA>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="RFF/PONum" />
					</Field>
				</Field>
				<xsl:if test="string-length(RFF/BillOfLadingNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>BM</Field>
					<Field>
						<xsl:value-of select="RFF/BillOfLadingNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/CarrierProNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CN</Field>
					<Field>
						<xsl:value-of select="RFF/CarrierProNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			</RFF>
			<NAD> <!-- NAD.BY -->
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.BY/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/Name2" />
					</Field>
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
					<xsl:value-of select="NAD.BY/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/Country" />
				</Field>
            </NAD>
            <NAD> <!-- NAD.SU -->
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
					<Field>
						<xsl:value-of select="NAD.SU/Name2" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/Country" />
				</Field>
            </NAD>
			<NAD> <!-- NAD.DP -->
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
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
					<Field>
						<xsl:value-of select="NAD.ST/Name2" />
					</Field>
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
					<xsl:value-of select="NAD.ST/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/Country" />
				</Field>
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="NAD.ST/CTA/BuyerName" />
					</Field>
				</CTA>
            </NAD>
            <TDT>
                <mapper:incVar name="segmentCount" />
                <Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
                <Field/>
                <Field/>
				<Field/>
                <Field>
                    <Field/>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="TDT/Routing" />
					</Field>
                </Field>
            </TDT>
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
					<Field>1E</Field>
				</CPS>
				<PAC>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="PAC/NumOfPackages" />
					</Field>
					<Field/>
					<Field>
						<xsl:value-of select="PAC/PackageType" />
					</Field>
				</PAC>
				<xsl:for-each select="Pack">
					<CPS>
						<mapper:incVar name="segmentCount" />
						<mapper:incVar name="packageIncrementer" />
						<Field>
							<mapper:getVar name="packageIncrementer" />
						</Field>
						<Field>1</Field>
						<Field>3</Field>
					</CPS>
					<PAC>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="PAC/NumOfPacks" />
						</Field>
						<Field/>
						<Field>
							<xsl:value-of select="PAC/CartonNum" />
						</Field>
					</PAC>
					<xsl:if test="string-length(MEA/Weight) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>EGW</Field>
						<Field>AAB</Field>
						<Field>
							<Field>KGM</Field>
							<Field>
								<xsl:value-of select="MEA/Weight" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(MEA/Volume) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>ABJ</Field>
						<Field>
							<Field>MTQ</Field>
							<Field>
								<xsl:value-of select="MEA/Volume" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(MEA/Height) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>HT</Field>
						<Field>
							<Field>CMT</Field>
							<Field>
								<xsl:value-of select="MEA/Height" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(MEA/Length) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>LN</Field>
						<Field>
							<Field>CMT</Field>
							<Field>
								<xsl:value-of select="MEA/Length" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(MEA/Width) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>WD</Field>
						<Field>
							<Field>CMT</Field>
							<Field>
								<xsl:value-of select="MEA/Width" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<PCI>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="PCI/MarkInstr" />
						</Field>
					</PCI>
					<GIN>
						<mapper:incVar name="segmentCount" />
						<Field>BJ</Field>
						<Field>
							<xsl:value-of select="GIN/ContainerCode" />
						</Field>
					</GIN>
					<xsl:for-each select="Details">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LineNum" />
						</Field>
						<Field/>
						<Field>
							<Field>
								<xsl:value-of select="BuyersItemNum" />
							</Field>
							<Field>IN</Field>
						</Field>
					</LIN>
					<xsl:if test="string-length(BuyersItemNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="ProductIDType" />
						</Field>
						<Field>
							<xsl:value-of select="BuyersItemNum" />
						</Field>
						<Field>IN</Field>
					</PIA>
					</xsl:if>
					<xsl:if test="string-length(SuppliersArticleNum) &gt; 0">
					<PIA>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="ProductIDType" />
						</Field>
						<Field>
							<xsl:value-of select="SuppliersArticleNum" />
						</Field>
						<Field>SA</Field>
					</PIA>
					</xsl:if>
					<IMD>
						<mapper:incVar name="segmentCount" />
						<Field>F</Field>
						<Field/>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="Description" />
							</Field>
						</Field>
					</IMD>
					<xsl:if test="string-length(ColorCode) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>X5E</Field>
						<Field/>
						<Field>
							<Field>ZZ</Field>
							<Field>
								<xsl:value-of select="ColorCode" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(SizeCode) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>X6E</Field>
						<Field/>
						<Field>
							<Field>ZZ</Field>
							<Field>
								<xsl:value-of select="SizeCode" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<QTY>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>113</Field>
							<Field>
								<xsl:value-of select="DespatchQty" />
							</Field>
							<Field>EA</Field>
						</Field>
					</QTY>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:for-each> 
            <CNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>2</Field>
                    <!-- 2 = total number of lines -->
                    <Field>
                        <xsl:value-of select="count(//Details)" />
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